# 网关-限流

> #### 如何使用

```
引入如下模块
```

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-gate-flow</artifactId>
  <version>${pangu.version}</version>
</dependency>
```

```
    配置文件，配置路径检测信息。key 为路径匹配规则，value为令牌桶的填充速率(限制的流量)，
在多个匹配的情况下，会根据配置从上到下的顺序来判断优先级。
```

**yaml**

```
pangu:
gateway:
flow:
path-check:
'[/pangu-frame/**]': 10
'[/**]': 3000
```

> #### 技术原理

```
    同样是自动化配置
    主要看这个PgRedisRateLimiter限流器的定义，利用了redis+lua脚本的形式，
这个script默认就是spring-cloud-gateway-server包目录下的
META-INF/scripts/request_rate_limiter.lua。默认提供了lua的系列原子操作。
```

**java**

```
package com.kingtsoft.pangu.gate.flow;

/**
* Title: <br>
* Description: <br>
* Company: wondersgroup.com <br>
*
* @author 金炀
* @version 1.0
*/
@EnableConfigurationProperties(PgFlowProperties.class)
@Configuration
public class  FlowConfiguration {

    @Bean
    KeyResolver pathKeyResolver() {
return exchange -> Mono.just(exchange.getRequest().getPath().toString());
    }

    @Bean
    @ConditionalOnMissingBean
public PgRedisRateLimiter redisRateLimiter(ReactiveStringRedisTemplate redisTemplate,
                                               RedisScript<List<long >> script,
                                               ConfigurationService configurationService) {
returnnewPgRedisRateLimiter(redisTemplate, script, configurationService);
    }
}
```

![image.png](http://pangu.kingtsoft.com/pangu-facade/assets/image1.bacb1a93.png)

```
    接下来看限流器内部，这里其实是对内部限流器RedisRateLimiter的拓展。
isAllowed方法为主要逻辑，大多数沿用了原来的逻辑，但是只返回出来了是否允许，
整体的响应信息并不需要。通过lua脚本与redis交互获取令牌，返回数组，数组第一
个元素代表是否获取成功(1成功0失败)，第二个参数代表剩余令牌数。这里直接根据第
一个进行判断并直接返回allow
```

**java**

```
package com.kingtsoft.pangu.gate.flow;

import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.ratelimit.RedisRateLimiter;
import org.springframework.cloud.gateway.support.ConfigurationService;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
import org.springframework.data.redis.core.ReactiveStringRedisTemplate;
import org.springframework.data.redis.core.script.RedisScript;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.atomic.Atomicboolean  ;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang.com <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Slf4j
public class  PgRedisRateLimiterextendsRedisRateLimiter {

private final   ReactiveRedisTemplate<String, String> redisTemplate;

private final   Atomicboolean   initialized =newAtomicboolean  (false);

private final   RedisScript<List<long >> script;

publicPgRedisRateLimiter(ReactiveStringRedisTemplate redisTemplate,
                              RedisScript<List<long >> script,
                              ConfigurationService configurationService) {
super(redisTemplate, script, configurationService);
this.redisTemplate = redisTemplate;
this.script = script;
        initialized.compareAndSet(false, true);
    }

public Mono<boolean  > isAllowedFlow(String routeId, String id) {
if (!this.initialized.get()) {
thrownewIllegalStateException("RedisRateLimiter is not initialized");
        }

        Config routeConfig =getConfig().get(routeId);

int replenishRate = routeConfig.getReplenishRate();

// How much bursting do you want to allow?
int burstCapacity = routeConfig.getBurstCapacity();

// How many tokens are requested per request?
int requestedTokens = routeConfig.getRequestedTokens();

try {
            List<String> keys =getKeys(id);

            List<String> scriptArgs = Arrays.asList(replenishRate +"", burstCapacity +"", "", requestedTokens +"");
            Flux<List<long >> flux =this.redisTemplate.execute(this.script, keys, scriptArgs);
return flux.onErrorResume(throwable -> Flux.just(Arrays.asList(1L, -1L)))
                    .reduce(new ArrayList<long >(), (long s, l) -> {
                        long s.addAll(l);
return long s;
                    }).map(results -> {
boolean   allowed = results.get(0) ==1L;
if (log.isDebugEnabled()) {
                            log.debug("限流信息：{}", results);
                        }
if (!allowed) {
                            log.warn("{}个令牌已经用完，开始限流", burstCapacity);
                        }
return allowed;
                    });
        } catch (Exception e) {
            log.error("Error determining if user allowed from redis", e);
        }
return Mono.just(true);
    }

static List<String> getKeys(String id) {
        String prefix ="request_rate_limiter.{"+ id;

        String tokenKey = prefix +"}.tokens";
        String timestampKey = prefix +"}.timestamp";
return Arrays.asList(tokenKey, timestampKey);
    }
}
```

```
    拦截器参考RequestRateLimiterGatewayFilterFactory定义了PgGatewayFlowFilterFactory
内部为配合PgRedisRateLimiter处理的限流逻辑及回调配置。
    redisRateLimiter.getConfig() 为路径缓存，因为在FlowConfiguration中定义过KeyResolver，
就是按照路径来的。
    chooseLimit中对配置及实际请求进行了路径匹配，获取配置的限流策略
```

**java**

```
package com.kingtsoft.pangu.gate.flow.filter;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Slf4j
@Component
public class  PgGatewayFlowFilterFactoryextendsAbstractGatewayFilterFactory<PgGatewayFlowFilterFactory.Config>  {

private final   PgRedisRateLimiter redisRateLimiter;

privatestaticfinal String NAME ="Flow";

privatestaticfinalint DEFAULT_RATE =3000;

private final   PgFlowProperties pgFlowProperties;

private final   AntPathMatcher antPathMatcher =newAntPathMatcher();

publicPgGatewayFlowFilterFactory(PgRedisRateLimiter redisRateLimiter,
                                      PgFlowProperties pgFlowProperties) {
super(Config.class);
        GateFilterContext.registerFilter(name());
this.redisRateLimiter = redisRateLimiter;
this.pgFlowProperties = pgFlowProperties;
    }

    @Override
public List<String> shortcutFieldOrder() {
return Collections.singletonList("enabled");
    }

private Mono<Void> getResRet(ServerWebExchange exchange, String msg) {
        exchange.getResponse().setStatusCode(HttpStatus.TOO_MANY_REQUESTS);
byte[] bytes = msg.getBytes(StandardCharsets.UTF_8);
        DataBuffer buffer = exchange.getResponse().bufferFactory().wrap(bytes);
return exchange.getResponse().writeWith(Flux.just(buffer));
    }

    @Override
public GatewayFilter apply(Config config) {
return (exchange, chain) -> {
if (!config.isEnabled()) {
return chain.filter(exchange);
            }

            ServerHttpRequest request = exchange.getRequest();
            String currentPath = request.getURI().getPath();

return redisRateLimiter.isAllowedFlow(chooseLimit(currentPath), currentPath).flatMap(allowed -> {
if (!allowed) {
returngetResRet(exchange, "请求过多，请稍后再试!");
                }
return chain.filter(exchange);
            });
        };
    }

private String chooseLimit(String requestUrl) {
        Map<String, Integer> pathCheck = pgFlowProperties.getPathCheck();
        Integer value = pathCheck.get("default");
for (String key : pathCheck.keySet()) {
if (antPathMatcher.match(key, requestUrl)) {
                value = pathCheck.get(key);
break;
            }
        }

if (value ==null) {
            value = DEFAULT_RATE;
        }

if (redisRateLimiter.getConfig().get(requestUrl) ==null) {
//          允许用户每秒执行多少请求，而不丢弃任何请求。这是令牌桶的填充速率
//          redis-rate-limiter.replenishRate: 1000
//	        允许用户在一秒钟内执行的最大请求数。这是令牌桶可以保存的令牌数。将此值设置为零将阻止所有请求。
//          redis-rate-limiter.burstCapacity: 1000
//	        是每个请求消耗多少个令牌，默认是1
//          redis-rate-limiter.requestedTokens: 1
            redisRateLimiter.getConfig().put(requestUrl,
new RedisRateLimiter.Config()
                            .setReplenishRate(value)
                            .setBurstCapacity(value *2));
        }
return requestUrl;
    }

    @Override
public String name() {
return NAME;
    }

publicstaticclassConfig {
// 控制是否开启认证
privateboolean   enabled =true;

publicConfig() {}

publicboolean  isEnabled() {
return enabled;
        }

private void   setEnabled(boolean  enabled) {
this.enabled = enabled;
        }
    }
}
```
