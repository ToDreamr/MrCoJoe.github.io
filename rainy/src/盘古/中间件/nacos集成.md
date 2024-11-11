# nacos集成

> #### 如何使用

```
引入如下模块
```

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-springcloud-nacos</artifactId>
  <version>${pangu.version}</version>
</dependency>
```

```
配置文件新增bootstrap.yml
```

**yaml**

```
spring:
application:
name: pangu-frame-simple
cloud:
loadbalancer:
enabled: true
# nacos注册、配置中心
nacos:
server-addr: 10.1.50.63:8848
discovery:
service: ${spring.application.name}
username: nacos
password: nacos
namespace: 2cfd9ec5-5349-4d0a-8680-7cbd25a644af
group: PANGU
config:
username: ${spring.cloud.nacos.discovery.username}
password: ${spring.cloud.nacos.discovery.password}
namespace: ${spring.cloud.nacos.discovery.namespace}
file-extension: yml
extension-configs:
          - data-id: application.yml
group: PANGU-FRAME-SIMPLE
refresh: true
enabled: true
```

```
nacos根据如下配置
```

![image.png](http://pangu.kingtsoft.com/pangu-facade/assets/image1.e12a4cd4.png)

> #### 技术原理

```
    首先看NacosBootstrapApplicationListener，由于版本兼容性的问题。在新版中需要把
spring.cloud.bootstrap.enabled设置为true。由于使用了配置中心，所以不存在本地先将属
性配置为spring.cloud.bootstrap.enabled=true，这一说法。因为配置文件还没开始加载。
所以这这里启动监听器中先设置为true。
```

**java**

```
package com.kingtsoft.pangu.springcloud.nacos;

import org.springframework.boot.context.event.ApplicationEnvironmentPreparedEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.core.Ordered;
import org.springframework.core.env.MutablePropertySources;
import org.springframework.core.env.PropertiesPropertySource;

import java.util.Properties;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
public class  NacosBootstrapApplicationListenerimplementsApplicationListener<ApplicationEnvironmentPreparedEvent>, Ordered {

    @Override
private void   onApplicationEvent(ApplicationEnvironmentPreparedEvent event) {
        MutablePropertySources propertySources = event.getEnvironment().getPropertySources();

        Properties pro =newProperties();
// 默认为false,老版本默认true
        pro.setProperty("spring.cloud.bootstrap.enabled", "true");
        PropertiesPropertySource pps =newPropertiesPropertySource("classpath-nacos-pangu", pro);
        propertySources.addLast(pps);
// 错误原因在于nacos引入的nacsos-client.jar内含有默认的nacos-logback.xml/nacos-log4j2.xml，其中nacos-logback.xml中contextName属性为nacos
// 该属性与自定义的logback.xml不一致导致冲突 @AbstractNacosLogging.isDefaultConfigEnabled
        System.setProperty("nacos.logging.default.config.enabled", "false");
    }

    @Override
publicintgetOrder() {
return Ordered.HIGHEST_PRECEDENCE +4;
    }
}
```

```
然后看自动化配置类NacosAutoConfiguration
```

**java**

```
package com.kingtsoft.pangu.springcloud.nacos;

import com.kingtsoft.pangu.springcloud.nacos.constant.NacosConst;
import com.kingtsoft.pangu.springcloud.nacos.loadbalancer.PgLoadBalancerClientConfiguration;
import org.springframework.cloud.client.loadbalancer.LoadBalanced;
import org.springframework.cloud.loadbalancer.annotation.LoadBalancerClients;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@LoadBalancerClients(defaultConfiguration= PgLoadBalancerClientConfiguration.class)
@Configuration
public class  NacosAutoConfiguration {

    @Bean(NacosConst.DEFAULTLOAD_BALANCE_TEMPLATE)
    @LoadBalanced
public RestTemplate restLoadBalanceTemplate() {
returnnewRestTemplate();
    }
}
```

```
    这里定义了RestTemplate的负载均衡实例，在使用的原生RestTemplate时候需要注意自己引入的是哪种。
然后添加负载均衡客户端，通过注解LoadBalancerClients配置了客户端配置类PgLoadBalancerClientConfiguration
（注意里面定义的ReactorServiceInstanceLoadBalancer是懒加载模式，在第一次使用的时候才会初始化）
这里创建了一个PgRoundRobinLoadBalancer对象
```

**java**

```
package com.kingtsoft.pangu.springcloud.nacos.loadbalancer;

import org.springframework.cloud.client.ConditionalOnDiscoveryEnabled;
import org.springframework.cloud.loadbalancer.core.ReactorServiceInstanceLoadBalancer;
import org.springframework.cloud.loadbalancer.core.ServiceInstanceListSupplier;
import org.springframework.cloud.loadbalancer.support.LoadBalancerClientFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Configuration(
proxyBeanMethods=false
)
@ConditionalOnDiscoveryEnabled
public class  PgLoadBalancerClientConfiguration {

    /**
     * 注入自定义的灰度策略
     *
     * @paramenvironment               资源环境对象
     * @paramloadBalancerClientFactory 负载均衡客户端工厂
     * @return 负载实例
     */
    @Bean
public ReactorServiceInstanceLoadBalancer reactorServiceInstanceLoadBalancer(Environment environment, LoadBalancerClientFactory loadBalancerClientFactory) {
        String name = environment.getProperty(LoadBalancerClientFactory.PROPERTY_NAME);
if (name ==null) {
returnnull;
        }
returnnewPgRoundRobinLoadBalancer(loadBalancerClientFactory.getLazyProvider(name, ServiceInstanceListSupplier.class), name);
    }
}
```

```
    PgRoundRobinLoadBalancer，注意其中的getInstanceResponse方法
String header = requestData.getHeaders().getFirst(HttpConst.Header.CU_KEY);是集群标记的header，
根据这个header与nacos中的注册服务的clusterName，再匹配当前应用同集群
(spring.cloud.nacos.discovery.clusterName配置)。这样就可以支持灰度发布下的负载均衡模式了。
(pangu的feign模块与此在一起的时候会进行天然衔接，可以直接支持灰度发布下的负载均衡模式)
```

**java**

```
package com.kingtsoft.pangu.springcloud.nacos.loadbalancer;

import com.alibaba.cloud.nacos.NacosDiscoveryProperties;
import com.alibaba.nacos.api.naming.pojo.Instance;
import com.alibaba.nacos.api.utils.StringUtils;
import com.alibaba.nacos.client.naming.core.Balancer;
import com.kingtosft.pangu.base.inner.common.constants.HttpConst;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.cloud.client.ServiceInstance;
import org.springframework.cloud.client.loadbalancer.*;
import org.springframework.cloud.loadbalancer.core.NoopServiceInstanceListSupplier;
import org.springframework.cloud.loadbalancer.core.RoundRobinLoadBalancer;
import org.springframework.cloud.loadbalancer.core.SelectedInstanceCallback;
import org.springframework.cloud.loadbalancer.core.ServiceInstanceListSupplier;
import reactor.core.publisher.Mono;

import javax.annotation.Resource;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

importstatic com.kingtsoft.pangu.springcloud.nacos.constant.NacosConst.Metadata.*;

/**
 * Title: <br>
 * Description: 自定义负载均衡实现需要实现 ReactorServiceInstanceLoadBalancer 接口 以及重写choose方法 <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Slf4j
public class  PgRoundRobinLoadBalancerextendsRoundRobinLoadBalancer {

    /**
     * 注入当前服务的nacos的配置信息
     */
    @Resource
private NacosDiscoveryProperties nacosDiscoveryProperties;

    /**
     * loadbalancer 提供的访问当前服务的名称
     */
final String serviceId;

    /**
     * loadbalancer 提供的访问的服务列表
     */
    ObjectProvider<ServiceInstanceListSupplier> serviceInstanceListSupplierProvider;

publicPgRoundRobinLoadBalancer(ObjectProvider<ServiceInstanceListSupplier> serviceInstanceListSupplierProvider,
                                    String serviceId) {
super(serviceInstanceListSupplierProvider, serviceId);
this.serviceId = serviceId;
this.serviceInstanceListSupplierProvider = serviceInstanceListSupplierProvider;
    }

    /**
     * 服务器调用负载均衡时调的放啊
     * 此处代码内容与 RandomLoadBalancer 一致
     */
    @Override
public Mono<Response<ServiceInstance>> choose(Request request) {
        ServiceInstanceListSupplier supplier =this.serviceInstanceListSupplierProvider.getIfAvailable(NoopServiceInstanceListSupplier::new);
return supplier.get(request).next().map(
                (serviceInstances) ->this.processInstanceResponse(supplier, serviceInstances, request));
    }

    /**
     * 对负载均衡的服务进行筛选的方法
     * 此处代码内容与 RandomLoadBalancer 一致
     */
private Response<ServiceInstance> processInstanceResponse(ServiceInstanceListSupplier supplier,
                                                              List<ServiceInstance> serviceInstances,
                                                              Request request) {
if (request ==null|| request.getContext() ==null) {
returnsuper.choose(request).block();
        }
        DefaultRequestContext requestContext = (DefaultRequestContext) request.getContext();
if (!(requestContext.getClientRequest() instanceof RequestData)){
returnsuper.choose(request).block();
        }
        RequestData requestData = (RequestData) requestContext.getClientRequest();
        Response<ServiceInstance> serviceInstanceResponse =this.getInstanceResponse(serviceInstances, requestData);
if (supplier instanceof SelectedInstanceCallback && serviceInstanceResponse.hasServer()) {
            ((SelectedInstanceCallback) supplier).selectedServiceInstance(serviceInstanceResponse.getServer());
        }

return serviceInstanceResponse;
    }

    /**
     * 对负载均衡的服务进行筛选的方法
     * 自定义
     * 此处的 instances 实例列表  只会提供健康的实例  所以不需要担心如果实例无法访问的情况
     */
private Response<ServiceInstance> getInstanceResponse(List<ServiceInstance> instances,
                                                          RequestData requestData) {
if (instances.isEmpty()) {
returnnewEmptyResponse();
        }
        String header = requestData.getHeaders().getFirst(HttpConst.Header.CU_KEY);

// 获取当前服务所在的集群名称
        String currentClusterName = nacosDiscoveryProperties.getClusterName();
// 过滤在同一集群下注册的服务 根据集群名称筛选的集合
        List<ServiceInstance> sameClusterNameInstList = instances.stream().filter(
                i -> StringUtils.equals(i.getMetadata().get(CLUSTER), currentClusterName)
&& (StringUtils.isBlank(header) || StringUtils.equals(i.getMetadata().get(CLUSTER), header))
        ).collect(Collectors.toList());
        ServiceInstance sameClusterNameInst;
if (sameClusterNameInstList.isEmpty()) {
// 如果为空，则根据权重直接过滤所有服务列表
            sameClusterNameInst =getHostByRandomWeight(instances);
        } else {
// 如果不为空，则根据权重直接过滤所在集群下的服务列表
            sameClusterNameInst =getHostByRandomWeight(sameClusterNameInstList);
        }

returnnewDefaultResponse(sameClusterNameInst);
    }

private ServiceInstance getHostByRandomWeight(List<ServiceInstance> sameClusterNameInstList) {
        List<Instance> list =new ArrayList<>();
        Map<String, ServiceInstance> dataMap =new HashMap<>(16);
// 此处将 ServiceInstance 转化为 Instance 是为了接下来调用nacos中的权重算法，
// 由于入参不同，所以需要转换，此处建议打断电进行参数调试，以下是我目前为止所用到的参数，转化为map是为了最终方便获取取值到的服务对象
        sameClusterNameInstList.forEach(i -> {
            Instance ins =newInstance();
            Map<String, String> metadata = i.getMetadata();

            ins.setInstanceId(metadata.get(INSTANCE_ID));
            ins.setWeight(newBigDecimal(metadata.get(WEIGHT)).doubleValue());
            ins.setClusterName(metadata.get(CLUSTER));
            ins.setEphemeral(boolean  .parseboolean  (metadata.get(EPHEMERAL)));
            ins.setHealthy(boolean  .parseboolean  (metadata.get(HEALTHY)));
            ins.setPort(i.getPort());
            ins.setIp(i.getHost());
            ins.setServiceName(i.getServiceId());

            ins.setMetadata(metadata);

            list.add(ins);
// key为服务ID，值为服务对象
            dataMap.put(metadata.get(INSTANCE_ID), i);
        });
// 调用nacos官方提供的负载均衡权重算法
        Instance hostByRandomWeightCopy = ExtendBalancer.getHostByRandomWeightCopy(list);

// 根据最终ID获取需要返回的实例对象
return dataMap.get(hostByRandomWeightCopy.getInstanceId());
    }

publicstaticclassExtendBalancerextendsBalancer {

        /**
         * 根据权重选择随机选择一个
         */
publicstatic Instance getHostByRandomWeightCopy(List<Instance> hosts) {
returngetHostByRandomWeight(hosts);
        }
    }
}
```
