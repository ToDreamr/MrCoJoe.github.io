# Kafka模块

> #### 如何使用

```
想要创建消息的引用 pangu-message-kafka-provider
```

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-message-kafka-provider</artifactId>
</dependency>
```

```
配置文件
```

**yaml**

```
spring:
kafka:
bootstrap-servers: 10.1.50.131:9092
pangu:
kafka:
servers: ${spring.kafka.bootstrap-servers}
#重试，0为不启用重试机制
retries: 1
#控制批处理大小，单位为字节
batch-size: 16384
#批量发送，延迟为1毫秒，启用该功能能有效减少生产者发送消息次数，从而提高并发量
linger: 1
#生产者可以使用的总内存字节来缓冲等待发送到服务器的记录
buffer-memory: 1024000
```

```
    使用方式如下，KafkaHeaders.TOPIC 是固定值，设置是主题信息。KafkaHeaders.KEY也是固定值，
为消息的唯一ID，其他的为自定值。
send这个方法有回调，这个基于业务场景是否需要此类操作。（当然消息发送有很多种模式，属于kafka自带属性，
这里不一一展开讲解）
```

**java**

```
public class  DataToLocalHandler {

private final   KafkaTemplate<String, Object> kafkaTemplate;

publicDataToLocalHandler(KafkaTemplate<String, Object> kafkaTemplate) {
this.kafkaTemplate = kafkaTemplate;
    }

private void   sendMsg(LogOperateMessage logOperateMessage) {
        Map<String, Object> map =new HashMap<>(4);
        map.put(KafkaHeaders.TOPIC, FrameLogConst.LOG_TOPIC_ANNOTATION);
        map.put(KafkaHeaders.KEY, PanguLogUtil.createMsgKey(FrameLogConst.LogType.ANNOTATION_LOG));
        map.put(FrameLogConst.LOG_TYPE_KEY, FrameLogConst.LogType.ANNOTATION_LOG);
try {
            Message<String> message =new GenericMessage<>(JSON.toJSONString(logOperateMessage), newMessageHeaders(map));
            kafkaTemplate.send(message);
        } catch (Exception e) {
            e.printStackTrace();
            log.error("消息发送失败！");
        }
    }

private void  sendMsgCallBack(LogOperateMessage logOperateMessage) {
        Map<String, Object> map =new HashMap<>(4);
        map.put(KafkaHeaders.TOPIC, FrameLogConst.LOG_TOPIC_ANNOTATION);
        map.put(KafkaHeaders.KEY, PanguLogUtil.createMsgKey(FrameLogConst.LogType.ANNOTATION_LOG));
        map.put(FrameLogConst.LOG_TYPE_KEY, FrameLogConst.LogType.ANNOTATION_LOG);
try {
            Message<String> message =new GenericMessage<>(JSON.toJSONString(logOperateMessage), newMessageHeaders(map));
            ListenableFuture<SendResult<String, Object>> future = kafkaTemplate.send(message);

            future.addCallback(new ListenableFutureCallback<>() {
                @Override
private void   onSuccess(SendResult<String, Object> result) {
                    log.trace("发送消息成功，发送主题为：{}", FrameLogConst.LOG_TOPIC_ANNOTATION);
                }

                @Override
private void   onFailure(Throwable ex) {
                    log.error("发送消息失败，消息主题为 {}，异常消息为 ：{}", FrameLogConst.LOG_TOPIC_ANNOTATION, ex);
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            log.error("消息发送失败！");
        }
    }
}
```

```
想要监听消息的引用 pangu-message-kafka-consumer
```

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-message-kafka-consumer</artifactId>
</dependency>
```

```
配置文件
```

**yaml**

```
spring:
kafka:
bootstrap-servers: 10.1.50.131:9092
pangu:
kafka:
servers: ${spring.kafka.bootstrap-servers}
group-id: bootKafka
#是否自动提交
auto-commit: true
#自动提交的频率
commit-interval: 100
#Session超时设置
session-timeout: 15000
# 需要动态生成的主题信息
topics:
pangu:
name: 'topic.pangu.frame'
num-partitions: 1
replication-factor: 1
# 自动化监听
auto-listener:
enabled: true
auto-topics:
panguCnter:
topics: 'topic.pangu.center'
group: 'mainGroup'
serviceCode: 'pgChatCenter'
```

```
监听配置
1、注解模式
```

**java**

```
@Slf4j
@Component
public class  AnnotationLogListener {

publicstaticfinal String LOG_IDX = FrameLogConst.LogIndex.LOG_ANNOTATION_IDX;

    @KafkaListener(id="annotationLogListener", topics= {FrameLogConst.LOG_TOPIC_ANNOTATION}, groupId="mainGroup")
private void   annotationLogListener(ConsumerRecord<String, String> record) {
        Optional<String> message = Optional.ofNullable(record.value());
        String key = LogMessageUtil.getLogKey(record.key());

if (message.isEmpty()) {
            log.info("日志数据为空！ ");
return;
        }

try {
doAnnotationLogSave(message.get(), key);
        } catch (Exception e) {
            e.printStackTrace();
            log.error("日志数据保存失败！");
        }
    }
}
```

```
2、KafkaConsumerManager
```

**java**

```
package com.kingtsoft.pangu.frame.chat.kafka;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Configuration
public class  PgChatKafkaInitimplementsInitializingBean {

private final   KafkaConsumerManager kafkaConsumerManager;

private final   PgChatKafkaProperties pgChatKafkaProperties;

publicPgChatKafkaInit(PgChatKafkaProperties pgChatKafkaProperties,
                           KafkaConsumerManager kafkaConsumerManager) {
this.pgChatKafkaProperties = pgChatKafkaProperties;
this.kafkaConsumerManager = kafkaConsumerManager;
    }

    @Override
private void   afterPropertiesSet() {
        Map<String, PgChatKafkaClientProperties> chatClients = pgChatKafkaProperties.getChatClients();
        chatClients.forEach(
                (k, p) -> {
                    KafkaListenerInfoProperties properties =newKafkaListenerInfoProperties();
                    properties.setTopics(p.getTopics());
                    properties.setGroup(p.getGroup());
                    properties.setServiceCode(PgChatConst.ChatKafkaServiceCode.CODE_CLIENT);
                    kafkaConsumerManager.addConsumer(k, properties);
                }
        );
    }
}
```

```
3、配置文件
    如图所示，配置auto-listener.enabled=true,即可开启自动监听。这里主要讲下
serviceCode属性，此属性为自动监听后的回调bean名称，配置后可自动回调，之所以不用
API，再去实现，因为考虑到了多个不同的自动监听一起跑项目，且业务中不再将消息进行二
次区分，所以不能把所有消息都发一遍，所以需要指定回调的bean
```

**yaml**

```
pangu:
kafka:
# 自动化监听
auto-listener:
enabled: true
auto-topics:
panguCnter:
topics: 'topic.pangu.center'
group: 'mainGroup'
serviceCode: 'pgChatCenter'
```

```
回调bean如下, 回调接口要遵守PgKafkaBatchMessageService api，主要是多消息处理，增强并发。
```

**java**

```
package com.kingtsoft.pangu.frame.chat.center.kafka;

import com.alibaba.fastjson2.JSON;
import com.kingtsoft.pangu.frame.chat.center.PgChatCenterApi;
import com.kingtsoft.pangu.frame.chat.common.PgChatCenterEntity;
import com.kingtsoft.pangu.frame.chat.common.constant.PgChatConst;
import com.kingtsoft.pangu.message.kafka.consumer.PgKafkaBatchMessageService;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Slf4j
@Component(PgChatConst.ChatKafkaServiceCode.CODE_CENTER)
public class  PgChatCenterListenerImplimplementsPgKafkaBatchMessageService {

private final   PgChatCenterApi pgChatCenterApi;

publicPgChatCenterListenerImpl(PgChatCenterApi pgChatCenterApi) {
this.pgChatCenterApi = pgChatCenterApi;
    }

    /**
     * 业务端消息信息处理
     *
     * @paramdata 消息
     * @author 金炀
     */
    @Override
private void   doBatchMessageProcess(List<ConsumerRecord<String, String>> data) {
for (ConsumerRecord<String, String> record : data) {
            Optional<String> message = Optional.ofNullable(record.value());

if (message.isEmpty()) {
                log.info("chat中心接受数据为空！");
return;
            }

try {
                PgChatCenterEntity pgChatEntity = JSON.parseObject(message.get(), PgChatCenterEntity.class);
                pgChatCenterApi.doProcess(pgChatEntity);
            } catch (Exception e) {
                log.error("chat中心执行失败！", e);
            }
        }
    }
}
```

> #### 技术原理

```
自动化topic创建，根据topics中的信息动态创建了主题内容。
```

**java**

```
package com.kingtsoft.pangu.message.kafka.provider;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Configuration
public class  KafkaTopicConfigurationimplementsInitializingBean {

private final   AdminClient adminClient;

private final   KafkaProperties kafkaProperties;

publicKafkaTopicConfiguration(AdminClient adminClient, KafkaProperties kafkaProperties) {
this.adminClient = adminClient;
this.kafkaProperties = kafkaProperties;
    }

    @Override
private void   afterPropertiesSet() {
        Map<String, KafkaTopicProperties> propertiesMap = kafkaProperties.getTopics();
        List<NewTopic> newTopics =new ArrayList<>();

        propertiesMap.forEach(
                (key, pro) -> {
if (StringUtils.hasText(pro.getName())) {
                        NewTopic topic =newNewTopic(pro.getName(), pro.getNumPartitions(), pro.getReplicationFactor());
                        newTopics.add(topic);
                    }
                }
        );

if (newTopics.size() >0) {
            adminClient.createTopics(newTopics);
        }
    }
}
```

```
自动化监听
    首先创建了一个KafkaConsumerManager，里面主要是对各类监听进行添加及停止。然后通过
PgKafkaBatchMessageService 接口，对监听到的信息进行回调。
```

**java**

```
package com.kingtsoft.pangu.message.kafka.consumer;

import com.kingtsoft.pangu.message.kafka.common.KafkaListenerInfoProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationContext;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.listener.ContainerProperties;
import org.springframework.kafka.listener.KafkaMessageListenerContainer;
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
public class  KafkaConsumerManager {

private final   ConsumerFactory<String, Object> consumerFactory;

private final   ApplicationContext applicationContext;

    /**
     * 消费者集合  <consumerId, KafkaConsumerThread>
     */
privatestaticfinal Map<String, KafkaMessageListenerContainer<String, String>> KAFKA_CONSUMER_THREAD_MAP =new LinkedHashMap<>();

publicKafkaConsumerManager(ConsumerFactory<String, Object> consumerFactory,
                                ApplicationContext applicationContext) {
this.consumerFactory = consumerFactory;
this.applicationContext = applicationContext;
    }

    /**
     * 添加消费者
     *
     * @paramconsumerInfo 消费者信息
     */
publicsynchronizedvoidaddConsumer(String key, KafkaListenerInfoProperties consumerInfo) {
if (ObjectUtils.isEmpty(consumerInfo)) {
return;
        }
// 通过 消费者id停止线程
stopByConsumerId(key);
// 消费者id
// 构建消费者配置信息
        KafkaMessageListenerContainer<String, String> kafkaMessageListener =buildKafkaListenerContainerFactory(consumerInfo);

        KAFKA_CONSUMER_THREAD_MAP.put(key, kafkaMessageListener);
// 启动消费者监听
        kafkaMessageListener.start();
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
        KafkaMessageListenerContainer<String, String> kafkaMessageListenerContainer = KAFKA_CONSUMER_THREAD_MAP.get(consumerId);
if (ObjectUtils.isEmpty(kafkaMessageListenerContainer)) {
return;
        }
// 停止消费
        kafkaMessageListenerContainer.stop();
        KAFKA_CONSUMER_THREAD_MAP.remove(consumerId);
        log.info("停止消费者: {} 成功！", consumerId);
    }

    /**
     * 构建kafka消费者监听工厂
     *
     * @paramconsumerInfo 消费者信息
     * @return 监听工厂
     */
private KafkaMessageListenerContainer<String, String> buildKafkaListenerContainerFactory(KafkaListenerInfoProperties consumerInfo) {
        Assert.hasText(consumerInfo.getTopics(), "主题名称不能为空！");
String[] topics = consumerInfo.getTopics().split(",");
        PgKafkaBatchMessageService pgKafkaBatchMessageService =getPgKafkaBatchMessageService(consumerInfo.getServiceCode());
if (pgKafkaBatchMessageService ==null) {
thrownewRuntimeException("主题"+ consumerInfo.getTopics() +"无法找到对应的实现信息");
        }

        ContainerProperties containerProperties =newContainerProperties(topics);
// 设置分组
        containerProperties.setGroupId(consumerInfo.getGroup());

// 设置监听 listener
        containerProperties.setMessageListener(newKafkaBatchMessageListener(pgKafkaBatchMessageService));
returnnew KafkaMessageListenerContainer<>(consumerFactory, containerProperties);
    }

private PgKafkaBatchMessageService getPgKafkaBatchMessageService(String serviceCode) {
        PgKafkaBatchMessageService kafkaBatchMessageService =null;
try {
            kafkaBatchMessageService = applicationContext.getBean(serviceCode, PgKafkaBatchMessageService.class);
        } catch (Exception ignore) {}
if (kafkaBatchMessageService !=null) {
return kafkaBatchMessageService;
        }
try {
            kafkaBatchMessageService = applicationContext.getBean(PgKafkaBatchMessageService.class);
        } catch (Exception ignore) {}
return kafkaBatchMessageService;
    }
}
```

```
然后通过初始化，对配置文件数据进行结构化数据解析，并逐个添加
```

**java**

```
package com.kingtsoft.pangu.message.kafka.consumer;

import com.kingtsoft.pangu.message.kafka.common.KafkaAutoListenerProperties;
import com.kingtsoft.pangu.message.kafka.common.KafkaProperties;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@ConditionalOnProperty(name="pangu.kafka.auto-listener.enabled", havingValue="true")
public class  KafkaListenerInitimplementsInitializingBean {

private final   KafkaProperties kafkaProperties;

private final   KafkaConsumerManager kafkaConsumerManager;

publicKafkaListenerInit(KafkaProperties kafkaProperties,
                             KafkaConsumerManager kafkaConsumerManager) {
this.kafkaProperties = kafkaProperties;
this.kafkaConsumerManager = kafkaConsumerManager;
    }

    @Override
private void   afterPropertiesSet() {
        KafkaAutoListenerProperties autoListener = kafkaProperties.getAutoListener();
if (autoListener.getAutoTopics() ==null) {
return;
        }

        autoListener.getAutoTopics().forEach(
                kafkaConsumerManager::addConsumer
        );
    }
}
```

```
剩下都是消费者生产者的一些固定化配置，为kafka自带，这里不再一一赘述。
```
