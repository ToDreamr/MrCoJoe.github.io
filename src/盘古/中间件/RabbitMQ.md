# Rabbitmq模块

> #### 如何使用

```
消息发送端引用
```

**xml**

```
<dependency>
    <groupId>com.kingtsoft.pangu</groupId>
    <artifactId>pangu-message-rabbitmq-provider</artifactId>
</dependency>
```

```
    注入或者new RabbitTemplate, 默认添加了一个RabbitTemplate，但是因为这个是单例的，
如果设置了回调，同项目所有都会有影响，所有根据实际情况去使用new还是注入。
```

**java**

```
@Bean
public RabbitTemplate panguRabbitTemplate(ConnectionFactory connectionFactory,
                                              PanguMessageProperties messageProperties) {
        RabbitTemplate rabbitTemplate =newRabbitTemplate();
        rabbitTemplate.setConnectionFactory(connectionFactory);
//设置开启Mandatory,才能触发回调函数,无论消息推送结果怎么样都强制调用回调函数
        rabbitTemplate.setMandatory(true);

// 针对网络原因导致连接断开，利用retryTemplate重连3次(只是重连不是使用时的重试)
        RetryTemplate retryTemplate =newRetryTemplate();
        retryTemplate.setRetryPolicy(newSimpleRetryPolicy(messageProperties.getRetryPolicy().getMaxAttempts()));
        rabbitTemplate.setRetryTemplate(retryTemplate);

        rabbitTemplate.setConfirmCallback((correlationData, ack, cause) -> {
if (log.isDebugEnabled()) {
                log.debug("相关数据: {}, 确认情况: {}, 原因: {}", correlationData, ack, cause);
            }
        });

        rabbitTemplate.setReturnsCallback(returned -> {
if (log.isDebugEnabled()) {
                log.debug("消息: {}, 回应码: {}, 回应信息: {}, 交换机: {}, 路由键: {} ",
                        returned.getMessage(),
                        returned.getReplyCode(),
                        returned.getReplyText(),
                        returned.getExchange(),
                        returned.getRoutingKey());
            }
        });

return rabbitTemplate;
    }
```

```
如下为2种常用案例，前一个无返回值，后一个有返回值。
    exchange 	交换机名
    routingKey 	路由键（与绑定的路由key所匹配）
示例的jsonObject为消息内容
方法二第四个参数为回调，示例配置了消息的存活时间，如果不设置，它会一直处于未消费状态。根据业务实际情况设置。(rabbitTemplate还有许多常用用法可以参考官方API)
```

**java**

```
rabbitTemplate.convertAndSend(exchange, routingKey, jsonObject.toJSONString());

rabbitTemplate.convertSendAndReceive(exchange, routingKey, jsonObject.toJSONString(), s -> {
if (ttl !=null) {
                            s.getMessageProperties().setExpiration(this.ttl.toString());
                        }
return s;
                    })
```

```
配置文件
```

**yaml**

```
spring:
#配置rabbitMq 服务器
rabbitmq:
#集群配置如下注释内容
  	#addresses: 10.1.50.163:5672,10.1.50.165:5672
host: 10.1.50.231
port: 5672
username: admin
password: ***
#虚拟host 可以不设置,使用server默认host
#    virtual-host: PGHost
#确认消息已发送到交换机(Exchange)
#    publisher-confirms: true
publisher-confirm-type: correlated
#确认消息已发送到队列(Queue)
publisher-returns: true
pangu:
rabbitmq:
retry-policy:
max-attempts: 5
retry-times: 3
# 动态生成的队列
queues:
redisQueue:
name: 'pangu.redis'
durable: true
exclusive: false
autoDelete: false
#队列中消息存活时间，也可以不设置，选择在发送的时候动态传入(已经生成的数据若没此数据，就不要额外配了，不会进行覆盖，反而第一次请求会很慢)
ttl: 5000
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
```

```
消息接收端引用
```

**xml**

```
<dependency>
    <groupId>com.kingtsoft.pangu</groupId>
    <artifactId>pangu-message-rabbitmq-consumer</artifactId>
</dependency>
```

```
监听配置
下图#{queuesNames.redis}为队列名称，注意示例内容返回的其实是个数组。也可以直接在上面写常量内容。
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

```
配置文件方式回调监听(会根据配置文件自动化监听进行bean的回调)
```

**java**

```
package com.kingtsoft.pangu.storage.redis.server;

import com.kingtsoft.pangu.message.rabbitmq.consumer.PgRabbitBatchMessageService;
import org.springframework.amqp.core.Message;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Component("pgRedisCenter")
public class  PgRabbitBatchMessageServiceImplimplementsPgRabbitBatchMessageService {
    @Override
private void   doBatchMessageProcess(List<Message> msgList) {
// 业务处理
    }
}
```

```
配置文件
```

**yaml**

```
spring:
#配置rabbitMq 服务器
rabbitmq:
#集群配置如下注释内容
  	#addresses: 10.1.50.163:5672,10.1.50.165:5672
host: 10.1.50.231
port: 5672
username: admin
password: ***
#虚拟host 可以不设置,使用server默认host
#    virtual-host: PGHost
#确认消息已发送到交换机(Exchange)
#    publisher-confirms: true
publisher-confirm-type: correlated
#确认消息已发送到队列(Queue)
publisher-returns: true
pangu:
rabbitmq:
#此为自动监听配置
auto-listener:
enabled: true
auto-topics:
pgRedisCenter:
topics: 'pangu.redis.test'
#回调的bean名称
serviceCode: 'pgRedisCenter'
```

```
注意，动态生成队列后，如果没在使用，管理页面是无法看到的。需要调用一次后才会实际生成，并被消费者所发现。（很奇葩这点）
```

> #### 技术原理

**生产者**

```
在bean初始化完成后，通过配置文件.动态对队列、交换机、绑定信息等进行初始化。
```

**java**

```
package com.kingtsoft.pangu.message.rabbitmq.provider;

import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.core.*;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.config.BeanDefinition;
import org.springframework.beans.factory.support.BeanDefinitionBuilder;
import org.springframework.beans.factory.support.DefaultListableBeanFactory;
import org.springframework.core.Ordered;
import org.springframework.core.PriorityOrdered;

import java.util.HashMap;
import java.util.Map;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Slf4j
public class  MessageBeanFactoryPostProcessorimplementsInitializingBean, PriorityOrdered {

    @Autowired
private DefaultListableBeanFactory beanFactory;

    @Override
publicintgetOrder() {
return Ordered.HIGHEST_PRECEDENCE;
    }

    @Override
private void   afterPropertiesSet() {
        PanguMessageProperties messageProperties = beanFactory.getBean(PanguMessageProperties.class);
initQueues(beanFactory, messageProperties.getQueues());
initExchanges(beanFactory, messageProperties.getExchanges());
initBindings(beanFactory, messageProperties.getBindings());
    }

private void  initQueues(DefaultListableBeanFactory beanFactory,
                            Map<String, QueueProperties> queues) {
        queues.forEach(
                (name, queueProperties) -> {
registerBeanDefinition(beanFactory, name);

                    Map<String, Object> argumentsMap =new HashMap<>(4);
if (queueProperties.getTtl() !=null) {
                        argumentsMap.put("x-message-ttl", queueProperties.getTtl());
                    }
//注册bean实例
                    beanFactory.registerSingleton(name, newQueue(
                            queueProperties.getName(),
                            queueProperties.isDurable(),
                            queueProperties.isExclusive(),
                            queueProperties.isAutoDelete(),
                            argumentsMap)
                    );
                }
        );
    }

private void  initExchanges(DefaultListableBeanFactory beanFactory,
                               Map<String, ExChangeProperties> exchanges) {
        exchanges.forEach(
                (name, exchangeProperties) -> {
registerBeanDefinition(beanFactory, name);
//注册bean实例
                    beanFactory.registerSingleton(name, getTargetExchange(exchangeProperties));
                }
        );
    }

private Exchange getTargetExchange(ExChangeProperties exchangeProperties) {
        Exchange exchange;
switch (exchangeProperties.getExchangeType()) {
case"fanoutExchange":
                exchange =newFanoutExchange(
                        exchangeProperties.getName(),
                        exchangeProperties.isDurable(),
                        exchangeProperties.isAutoDelete());
break;
case"headersExchange":
                exchange =newHeadersExchange(
                        exchangeProperties.getName(),
                        exchangeProperties.isDurable(),
                        exchangeProperties.isAutoDelete());
break;
case"directExchange":
                exchange =newDirectExchange(
                        exchangeProperties.getName(),
                        exchangeProperties.isDurable(),
                        exchangeProperties.isAutoDelete());
break;
default:
                exchange =newTopicExchange(
                        exchangeProperties.getName(),
                        exchangeProperties.isDurable(),
                        exchangeProperties.isAutoDelete());
        }

return exchange;
    }

private void  initBindings(DefaultListableBeanFactory beanFactory,
                              Map<String, BindingProperties> bindings) {
        bindings.forEach(
                (name, bindingProperties) -> {
registerBeanDefinition(beanFactory, name);

//注册Bean定义，容器根据定义返回bean
                    beanFactory.registerSingleton(name, getTargetBinding(bindingProperties));
                }
        );
    }

private Binding getTargetBinding(BindingProperties bindingProperties) {
        Queue queue = (Queue) beanFactory.getBean(bindingProperties.getQueue());
        Exchange exchange = (Exchange) beanFactory.getBean(bindingProperties.getExchange());
return BindingBuilder.bind(queue).to(exchange).with(bindingProperties.getRoutingKey()).noargs();
    }

private void  registerBeanDefinition(DefaultListableBeanFactory beanFactory, String name) {
        BeanDefinitionBuilder beanDefinitionBuilder = BeanDefinitionBuilder.genericBeanDefinition(Binding.class);
        beanDefinitionBuilder.addPropertyReference(name, name);
        BeanDefinition beanDefinition = beanDefinitionBuilder.getRawBeanDefinition();
        beanFactory.registerBeanDefinition(name, beanDefinition);
    }
}
```

**消费者**

```
    设计了消息监听的处理类RabbitConsumerManager。外部若想用也可以直接注入此类。
也可以参照里面的方法自己去实现监听。(注意，配置文件的监听是不存在返回值的，官方amqp
种的监听api并未实现任何又返回参数的消息，要么用注解，要么自动写连接工厂并且使用阻塞
的模式进行手动返回)
```

**java**

```
package com.kingtsoft.pangu.message.rabbitmq.consumer;

import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.listener.MessageListenerContainer;
import org.springframework.amqp.rabbit.listener.SimpleMessageListenerContainer;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;
import org.springframework.util.Assert;
import org.springframework.util.ObjectUtils;
import org.springframework.util.StringUtils;

import java.util.LinkedHashMap;
import java.util.Map;

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
public class  RabbitConsumerManager {

private final   ConnectionFactory connectionFactory;

private final   ApplicationContext applicationContext;

    /**
     * 消费者集合  <consumerId, MessageListenerContainer>
     */
privatestaticfinal Map<String, MessageListenerContainer> RABBIT_CONSUMER_THREAD_MAP =new LinkedHashMap<>();

publicRabbitConsumerManager(ConnectionFactory connectionFactory,
                                 ApplicationContext applicationContext) {
this.connectionFactory = connectionFactory;
this.applicationContext = applicationContext;
    }

    /**
     * 添加消费者
     *
     * @paramconsumerInfo 消费者信息
     */
publicsynchronizedvoidaddConsumer(String key, RabbitListenerInfoProperties consumerInfo) {
if (ObjectUtils.isEmpty(consumerInfo)) {
return;
        }
// 通过 消费者id停止线程
stopByConsumerId(key);
// 消费者id
// 构建消费者配置信息
        MessageListenerContainer messageListener =buildListenerContainerFactory(consumerInfo);

        RABBIT_CONSUMER_THREAD_MAP.put(key, messageListener);
// 启动消费者监听
        messageListener.start();
        log.info("创建消费者: {} 成功！", key);
    }

    /**
     * 停止消除
     *
     * @paramconsumerId 消费者id
     */
private void   stopByConsumerId(String consumerId) {
if (!StringUtils.hasText(consumerId)) {
return;
        }
        MessageListenerContainer messageListenerContainer = RABBIT_CONSUMER_THREAD_MAP.get(consumerId);
if (ObjectUtils.isEmpty(messageListenerContainer)) {
return;
        }
// 停止消费
        messageListenerContainer.stop();
        RABBIT_CONSUMER_THREAD_MAP.remove(consumerId);
        log.info("停止消费者: {} 成功！", consumerId);
    }

    /**
     * 构建消费者监听工厂
     *
     * @paramconsumerInfo 消费者信息
     * @return 监听工厂
     */
private MessageListenerContainer buildListenerContainerFactory(RabbitListenerInfoProperties consumerInfo) {
        MessageListenerContainer messageListenerContainer =newSimpleMessageListenerContainer(connectionFactory);

        Assert.hasText(consumerInfo.getTopics(), "主题名称不能为空！");
String[] topics = consumerInfo.getTopics().split(",");
        messageListenerContainer.setQueueNames(topics);

        PgRabbitBatchMessageService pgRabbitBatchMessageService =getPgBatchMessageService(consumerInfo.getServiceCode());
if (pgRabbitBatchMessageService ==null) {
thrownewRuntimeException("主题"+ consumerInfo.getTopics() +"无法找到对应的实现信息");
        }

// 监听中注入了所属的回调bean
        messageListenerContainer.setupMessageListener(newPgBatchMessageListener(pgRabbitBatchMessageService));

return messageListenerContainer;
    }

// 进行回调bean匹配
private PgRabbitBatchMessageService getPgBatchMessageService(String serviceCode) {
        PgRabbitBatchMessageService batchMessageService =null;
try {
// 匹配定义内容
            batchMessageService = applicationContext.getBean(serviceCode, PgRabbitBatchMessageService.class);
        } catch (Exception ignore) {}
if (batchMessageService !=null) {
return batchMessageService;
        }
try {
// 定义不存在则去匹配任意符合api的bean（这里业务如果设置不好，会导致错乱监听）
            batchMessageService = applicationContext.getBean(PgRabbitBatchMessageService.class);
        } catch (Exception ignore) {}
return batchMessageService;
    }
}
```
