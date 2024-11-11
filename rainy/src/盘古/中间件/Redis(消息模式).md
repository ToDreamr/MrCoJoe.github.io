# Redis模块（消息模式）

> #### 如何使用

```
    此模块默认为中心端模式，需要独立启动一个redis的微服务（可以是box模式），包会线上提供
server的配置文件示例pangu.redis.queues属性根据实际与API一样就行, 可以参考rabbit详解内的重试添加redis重试机制
这里配置了固定端口主要是为了增加服务的可观察性
```

**yaml**

```
server:
port: 10245
spring:
application:
name: pangu-redis
#配置rabbitMq 服务器
rabbitmq:
#集群如下
#    addresses: 10.1.50.63:5672,10.1.50.65:5672
host: 10.1.50.231
port: 5672
username: admin
password: kingtang
#确认消息已发送到交换机(Exchange)
#    publisher-confirms: true
publisher-confirm-type: correlated
#确认消息已发送到队列(Queue)
#    publisher-returns: true
redis:
#集群如下
#    cluster:
#      nodes:
#        - 10.1.50.63:6380
#        - 10.1.50.63:6381
#        - 10.1.50.63:6382
host: 10.1.50.163
password: 0234kz9*l
port: 6379

pangu:
redis:
queues: 'pangu.redis'
# 这里利用rabbitmq初始化了redis数据交互的基础消息结构
rabbitmq:
queues:
redisQueue:
name: 'pangu.redis'
durable: true
exclusive: false
autoDelete: false
# 动态生成的交换器
exchanges:
#ExchangeType 属性可以配置类型 fanoutExchange\headersExchange\directExchange 未匹配或不写的会使用TopicExchange
redisExchange:
name: 'redis.exchange'
# 动态生成绑定关系
bindings:
bindingRedisExchangeMessage:
queue: redisQueue
exchange: redisExchange
#注意这个并非队列名
routingKey: 'pangu.redis'
#  rabbitmq:
#    auto-listener:
#      enabled: true
#      auto-topics:
#        pgRedisCenter:
#          topics: 'pangu.redis.test'
#          serviceCode: 'pgRedisCenter'
```

```
业务端引用如下模块
```

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-storage-redis-api</artifactId>
  <version>${pangu.version}</version>
</dependency>
```

```
业务端配置
```

**yaml**

```
pangu:
redis:
# 消息模式执行缓存
type: MQ
rabbitMq:
receiveTimeout: 5000
replyTimeout: 5000
```

```
注入redisHandler，并直接使用
```

**java**

```
public class  TraceController {

private final   RedisHandler<String, String> redisHandler;

    @RequestMapping("/getTrace")
public Object getTrace(HttpServletRequest request) {
        String dataKey = (String) request.getAttribute(TraceConst.SQL_TRACE_KEY);
if (dataKey ==null) {
thrownewTipException(ResCodeEnum.ERROR.getCode(), "请先开启SQL跟踪状态！");
        }
        String traceStr = redisHandler.get(dataKey);
if (traceStr ==null) {
return JsonResult.create(ResCodeEnum.SUCCESS);
        } else {
            JSONArray traceArr = JSON.parseArray(traceStr);
return JsonResult.create(traceArr);
        }
    }

}
```

```
目前支持的方法
```

**java**

```
package com.kingtsoft.pangu.storage.redis.api.handler;

import org.springframework.lang.Nullable;

import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
public interface  RedisHandler<K, V> {

    @Nullable
    boolean   setExpireTime(K key, long timeout, TimeUnit unit);

defaultvoidset(K key, V value) {
this.set(key, value, null, null);
    }

voidset(K key, V value, long  timeout, TimeUnit unit);

defaultvoidset(K key, V value, long timeout, TimeUnit unit) {
this.set(key, value, (long ) timeout, unit);
    }

    @Nullable
    boolean   setIfAbsent(K key, V value);

    @Nullable
    boolean   setIfAbsent(K key, V value, long timeout, TimeUnit unit);

    @Nullable
    boolean   setIfPresent(K key, V value);

    @Nullable
    boolean   setIfPresent(K key, V value, long timeout, TimeUnit unit);

    @Nullable
    V get(Object key);

    @Nullable
    boolean   delete(K key);

    /**
     * 将value从右边放入缓存
     *
     * @paramkey   键
     * @paramvalue 值
     */
    long  listRightPush(K key, V value);

    /**
     * 将value从左边放入缓存
     *
     * @paramkey   键
     * @paramvalue 值
     */
    long  listLeftPush(K key, V value);

    /**
     * 将list从右边放入缓存
     *
     * @paramkey   键
     * @paramvalue 值
     */
    long  listRightPushAll(K key, List<V> value);
    /**
     * 将list从左边放入缓存
     *
     * @paramkey   键
     * @paramvalue 值
     */
    long  listLeftPushAll(K key, List<V> value);

    /**
     * 从list左边弹出一条数据
     *
     * @paramkey 键
     * @return 队列中的值
     */
    V listLeftPop(K key);

    /**
     * 从list左边定时弹出一条
     *
     * @paramkey     键
     * @paramtimeout 弹出时间
     * @paramunit    时间单位
     * @return 队列中的值
     */
    V listLeftPop(K key, long timeout, TimeUnit unit);

    /**
     * 从list右边弹出一条数据
     *
     * @paramkey 键
     * @return 队列中的值
     */
    V listRightPop(K key);

    /**
     * 从list左边定时弹出
     *
     * @paramkey     键
     * @paramtimeout 弹出时间
     * @paramunit    时间单位
     * @return 队列中的值
     */
    V listRightPop(K key, long timeout, TimeUnit unit);

    List<V> listRange(K key, long start, long end);

    /**
     * 获取list缓存的长度
     *
     * @paramkey 键
     * @return list长度
     */
long listSize(K key);
}
```

> #### 技术原理

```
    缓存设计了独立的API模块，提供业务模块引用及初始化  接口 -> 抽象->实例 装饰模式下，
可根据实际包的引用或者配置（目前是根据包的引用），判断是否实例化途径。支持多个redis构造
器同时存在，并且抽象了注册方式及注册条件，使后期可以根据配置及其他情况进行创建器的创建与否。
```

**java**

```
public interface  RedisHandlerCreator {

    /**
     * 通过属性创建redis交互模式
     *
     * @paramredisHandlerProperties 操作属性
     * @return 被创建的数据源
     */
    RedisHandler createDataSource(RedisHandlerProperties redisHandlerProperties);

    /**
     * 当前创建器是否支持根据此属性创建
     *
     * @paramredisHandlerProperties 操作属性
     * @return 是否支持
     */
boolean  support(RedisHandlerProperties redisHandlerProperties);

}
```

**java**

```
publicabstractclassAbstractRedisHandlerCreatorimplementsRedisHandlerCreator {

publicabstract RedisHandler doCreateRedisHandler(RedisHandlerProperties redisHandlerProperties);

    /**
     * 这样可以保证存在共性内容就可以用抽象类抽取，而且不损失接口功能
     */
    @Override
public RedisHandler createDataSource(RedisHandlerProperties redisHandlerProperties) {
returndoCreateRedisHandler(redisHandlerProperties);
    }
}
```

**java**

```
package com.kingtsoft.pangu.storage.redis.api.creator;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Slf4j
public class  RedisMessageHandlerCreatorextendsAbstractRedisHandlerCreatorimplementsRedisHandlerCreator {

    @Autowired
private ConnectionFactory connectionFactory;

    /**
     * 具体实现
     */
    @Override
public RedisHandler doCreateRedisHandler(RedisHandlerProperties redisHandlerProperties) {
        RabbitTemplate rabbitTemplate =getRabbitTemplate(connectionFactory, redisHandlerProperties);

        RedisRetryPolicyProperties retryPolicy = redisHandlerProperties.getRetryPolicy();
        RetryTemplate retryTemplate =newRetryTemplate();
        retryTemplate.setRetryPolicy(newSimpleRetryPolicy(retryPolicy.getRetryTimes()));

returnnewRedisMessageHandler().build(rabbitTemplate, retryTemplate,
                StringUtils.hasText(redisHandlerProperties.getRoutingKey()) ?
                        redisHandlerProperties.getRoutingKey() :null,
                redisHandlerProperties.getTtl());
    }

    @Override
publicboolean  support(RedisHandlerProperties redisHandlerProperties) {
return redisHandlerProperties.getType() ==null||"MQ".equals(redisHandlerProperties.getType());
    }

public RabbitTemplate getRabbitTemplate(ConnectionFactory connectionFactory,
                                            RedisHandlerProperties redisHandlerProperties) {
        RabbitTemplate rabbitTemplate =newRabbitTemplate();
        rabbitTemplate.setConnectionFactory(connectionFactory);
//设置开启Mandatory,才能触发回调函数,无论消息推送结果怎么样都强制调用回调函数
        rabbitTemplate.setMandatory(true);
        rabbitTemplate.setReturnsCallback(returned -> {
if (log.isDebugEnabled()) {
                log.debug("RedisReturnsCallback消息: {}, 回应码: {}, 回应信息: {}, 交换机: {}, 路由键: {} ",
                        returned.getMessage(),
                        returned.getReplyCode(),
                        returned.getReplyText(),
                        returned.getExchange(),
                        returned.getRoutingKey());
            }
        });

if (redisHandlerProperties.getRabbitMq() !=null) {
            rabbitTemplate.setReceiveTimeout(redisHandlerProperties.getRabbitMq().getReceiveTimeout());
            rabbitTemplate.setReplyTimeout(redisHandlerProperties.getRabbitMq().getReplyTimeout());
        }
        rabbitTemplate.setReplyErrorHandler(t -> {
// 这里可以记录日志
            log.error("ReplyError: ", t);
        });

return rabbitTemplate;
    }
}
```

```
然后构建器根据注册的途径与匹配方式进行实际执行器获取
```

**java**

```
@Slf4j
@Setter
public class  DefaultRedisHandlerCreator {

private List<RedisHandlerCreator> creators;

public RedisHandler createRedisHandler(RedisHandlerProperties redisHandlerProperties) {
        RedisHandlerCreator redisHandlerCreator =null;
for (RedisHandlerCreator creator :this.creators) {
if (creator.support(redisHandlerProperties)) {
                redisHandlerCreator = creator;
break;
            }
        }
if (redisHandlerCreator ==null) {
thrownewIllegalStateException("creator must not be null, please check the DataSourceCreator");
        }
return redisHandlerCreator.createDataSource(redisHandlerProperties);
    }

}
```

```
    Redis本身的调用为了尽量避免网络方面的问题，加入了重试功能，后面的配置retry-times
为消息发送重试次数。而maxAttempts为连接的重试次数。
```

**java**

```
private Object doRetry(Function<Void, Object> function, Function<Void, Object> failCallBack) {
try {
        AtomicInteger i =newAtomicInteger(1);
return retryTemplate.execute((RetryCallback<Object, Throwable>) context -> {
if (i.get() >1) {
                log.info("开始第{}次redis消息重试, routingKey: {}", i.get() -1, routingKey);
            }
//需要重试的代码
            Object ret = function.apply(null);
            i.getAndIncrement();
if (ret ==null) {
thrownewRuntimeException("信息传递异常，详见错误信息！");
            }
return ret;
        }, context -> {
//重试失败后执行的代码
            log.error("消息重试了3次，无法正确调用");
return failCallBack.apply(null);
        });
    } catch (Throwable e) {
thrownewRuntimeException(e.getMessage());
    }
}
```

```
重试配置文件
```

**yaml**

```
pangu:
redis:
retry-policy:
max-attempts: 5
retry-times: 3
```

```
内置了一个时间过期类，可以让数据频繁过期的情况下，分批集中在一部分时间内过期，减少平时的负载及压力。
```

**java**

```
privatestaticfinal Map<TimeUnit, Integer> TIME_ALL =new HashMap<>() {
    {
put(TimeUnit.SECONDS, 3600);
put(TimeUnit.MINUTES, 60);
put(TimeUnit.HOURS, 24);
    }
};


publicstaticlong getExpTimeout(LocalDateTime startTime, long  timeout, int blockTime, TimeUnit unit) {
    Integer timeAll = TIME_ALL.get(unit);
if (timeAll ==null) {
thrownewRuntimeException("不支持的时间单位计算");
    }
if (blockTime > timeAll) {
thrownewRuntimeException("请使用小于等于60的解释数据");
    }
long  b = timeAll / blockTime;

int target;
if (TimeUnit.HOURS.equals(unit)) {
        target = startTime.plusHours(timeout).getHour();
    } elseif (TimeUnit.SECONDS.equals(unit)) {
        target = startTime.plusSeconds(timeout).getSecond();
    } else {
        target = startTime.plusMinutes(timeout).getMinute();
    }
int min = target;
for (int i =0; i < b; i++) {
int now = target - (i +1) * blockTime;
if (Math.abs(now) < Math.abs(min)) {
            min = now;
        }
    }

return timeout - min;
}
```

```
实际处理端(redis-server)
```

**java**

```
@RabbitHandler
@RabbitListener(queues="#{queuesNames.redis}")
public Object process(Message message) {
long  start = System.currentTimeMillis();

try {
if (redisReceiver ==null) {
            redisReceiver = applicationContext.getBean(PgRedisReceiver.class);
        }

        String body =newString(message.getBody(), StandardCharsets.UTF_8);
        JSONObject obj = JSON.parseObject(body);

        JSONObject messageContent = obj.getJSONObject(PgRedisConst.MessageBody.MESSAGE_CONTENT);
        Method method = ReflectionUtils.findMethod(
                redisReceiver.getClass(),
                obj.getString(PgRedisConst.MessageBody.MESSAGE_CODE),
                JSONObject.class);
if (method ==null) {
thrownewRuntimeException("方法不存在!");
        }
        Object ret = ReflectionUtils.invokeMethod(method, redisReceiver, messageContent);
// 如果返回是null，这边会卡好几秒
return ret ==null? PgRedisConst.MessageBody.RET_NULL_FLAG : ret;
    } catch (Exception e) {
return PgRedisConst.MessageBody.RET_EXCEPTION_FLAG;
    } finally {
if (log.isDebugEnabled()) {
            log.debug("cost-cus: {}", (System.currentTimeMillis() - start));
        }
    }
}
```
