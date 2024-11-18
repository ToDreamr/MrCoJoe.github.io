# chat模块

> #### 如何使用

```
后端
业务项目依赖如下的pangu-frame-chat-api模块
```

**xml**

```
<dependency>
    <groupId>com.kingtsoft.pangu</groupId>
    <artifactId>pangu-frame-chat-api</artifactId>
</dependency>
```

```
业务的启动器依赖如下的pangu-frame-chat模块
```

**xml**

```
<dependency>
    <groupId>com.kingtsoft.pangu</groupId>
    <artifactId>pangu-frame-chat</artifactId>
</dependency>
```

```
配置chat 的客户端实现，用于获取中心端发送的消息信息&信息发送接口
```

**java**

```
package com.kingtsoft.pangu.frame.simple.test.listener;

import com.kingtsoft.pangu.frame.chat.api.PgChatClientApi;
import com.kingtsoft.pangu.frame.chat.api.PgChatTemplate;
import com.kingtsoft.pangu.frame.chat.common.PgChatEntity;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.List;
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
public class  PgChatClientImplimplementsPgChatClientApi {

private final   PgChatTemplate pgChatTemplate;

publicPgChatClientImpl(PgChatTemplate pgChatTemplate) {
this.pgChatTemplate = pgChatTemplate;
    }

    /**
     * 业务端消息信息处理
     *
     * @paramchatList 消息
     * @author 金炀
     */
    @Override
private void   doChatProcess(List<PgChatEntity> chatList) {
for (PgChatEntity pgChatEntity : chatList) {
try {
                System.out.println(pgChatEntity.getContext());

                Map<String, Object> m =new HashMap<>(4);
                m.put("empId", 1);
                pgChatTemplate.sendChat("pangu", "群发了", 1, m);
            } catch (Exception e) {
                log.error("日志业务端数据处理失败！", e);
            }
        }
    }
}
```

```
PgChatTemplate类
    topicCode为消息主题代码，主要让中心端识别是哪个模块过来的，比如经济可以是emis，
但是也可以降级，比如一个挂号一个主题叫register（注意，并非kafka主题，这里中心端的
kafka主题是固定的）。若调用了不带topicCode的方法，会使用pangu.chat.topic-code
配置所配置的内容，可以在项目配置文件内配置。（一般配常量类里）
```

**java**

```
package com.kingtsoft.pangu.frame.chat.api;

import java.util.List;
import java.util.Map;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
public interface  PgChatTemplate {

    /**
     * 发送信息
     *
     * @paramcontext 信息
     * @author 金炀
     */
voidsendChat(String context);

    /**
     * 发送信息
     *
     * @paramcontext 信息
     * @paramtimeout 有效时间（毫秒）
     * @author 金炀
     */
voidsendChat(String context, long timeout);

    /**
     * 发送信息
     *
     * @paramcontext  信息
     * @parammetaInfo 附加信息
     * @author 金炀
     */
voidsendChat(String context, Map<String, Object> metaInfo);

    /**
     * 发送信息
     *
     * @paramcontext  信息
     * @parammetaInfo 附加信息
     * @paramtimeout  有效时间（毫秒）
     * @author 金炀
     */
voidsendChat(String context, Map<String, Object> metaInfo, long timeout);

    /**
     * 发送信息
     *
     * @paramcontext   信息
     * @parammetaInfos 附加信息
     * @author 金炀
     */
voidsendChat(String context, List<Map<String, Object>> metaInfos);

    /**
     * 发送信息
     *
     * @paramcontext   信息
     * @parammetaInfos 附加信息
     * @paramtimeout   有效时间（毫秒）
     * @author 金炀
     */
voidsendChat(String context, List<Map<String, Object>> metaInfos, long timeout);

    /**
     * 发送信息
     *
     * @paramtopicCode 主题信息
     * @paramcontext   信息
     * @author 金炀
     */
voidsendChat(String topicCode, String context);

    /**
     * 发送信息
     *
     * @paramtopicCode 主题信息
     * @paramcontext   信息
     * @paramtimeout   有效时间（毫秒）
     * @author 金炀
     */
voidsendChat(String topicCode, String context, long timeout);

    /**
     * 发送信息
     *
     * @paramtopicCode 主题信息
     * @paramcontext   信息
     * @parammetaInfo  附加信息
     * @author 金炀
     */
voidsendChat(String topicCode, String context, Map<String, Object> metaInfo);

    /**
     * 发送信息
     *
     * @paramtopicCode 主题信息
     * @paramcontext   信息
     * @parammetaInfo  附加信息
     * @paramtimeout   有效时间（毫秒）
     * @author 金炀
     */
voidsendChat(String topicCode, String context, Map<String, Object> metaInfo, long timeout);

    /**
     * 发送信息
     *
     * @paramtopicCode 主题信息
     * @paramcontext   信息
     * @parammetaInfos 附加信息
     * @author 金炀
     */
voidsendChat(String topicCode, String context, List<Map<String, Object>> metaInfos);

    /**
     * 发送信息
     *
     * @paramtopicCode 主题信息
     * @paramcontext   信息
     * @parammetaInfos 附加信息
     * @paramtimeout   有效时间（毫秒）
     * @author 金炀
     */
voidsendChat(String topicCode, String context, List<Map<String, Object>> metaInfos, long timeout);

    /**
     * 发送信息
     *
     * @paramtopicCode 主题信息
     * @paramcontext   信息
     * @parammsgType   信息类型 1-转发指定客户端 2-同组转发
     * @author 金炀
     */
voidsendChat(String topicCode, String context, Integer msgType);

    /**
     * 发送信息
     *
     * @paramtopicCode 主题信息
     * @paramcontext   信息
     * @parammsgType   信息类型 1-转发指定客户端 2-同组转发
     * @paramtimeout   有效时间（毫秒）
     * @author 金炀
     */
voidsendChat(String topicCode, String context, Integer msgType, long timeout);

    /**
     * 发送信息
     *
     * @paramtopicCode 主题信息
     * @paramcontext   信息
     * @parammsgType   信息类型 1-转发指定客户端 2-同组转发
     * @parammetaInfo  附加信息
     * @author 金炀
     */
voidsendChat(String topicCode, String context, Integer msgType, Map<String, Object> metaInfo);

    /**
     * 发送信息
     *
     * @paramtopicCode 主题信息
     * @paramcontext   信息
     * @parammsgType   信息类型 1-转发指定客户端 2-同组转发
     * @parammetaInfo  附加信息
     * @paramtimeout   有效时间（毫秒）
     * @author 金炀
     */
voidsendChat(String topicCode, String context, Integer msgType, Map<String, Object> metaInfo, long timeout);

    /**
     * 发送信息
     *
     * @paramtopicCode 主题信息
     * @paramcontext   信息
     * @parammsgType   信息类型 1-转发指定客户端 2-同组转发
     * @parammetaInfos 附加信息
     * @author 金炀
     */
voidsendChat(String topicCode, String context, Integer msgType, List<Map<String, Object>> metaInfos);

    /**
     * 发送信息
     *
     * @paramtopicCode 主题信息
     * @paramcontext   信息
     * @parammsgType   信息类型 1-转发指定客户端 2-同组转发
     * @parammetaInfos 附加信息
     * @paramtimeout   有效时间（毫秒）
     * @author 金炀
     */
voidsendChat(String topicCode, String context, Integer msgType, List<Map<String, Object>> metaInfos, long timeout);
}
```

```
配置文件
    配置kafka (chat-clients中配置的为客户端监听会启动自动监听模式，开启后才会回调clientCode所对应的
bean名称的PgChatClientApi接口实现，key为监听ID，topics为监听的主题信息，多个以逗号分隔。group为分组。
pangu.kafka.topics 的配置用于主题信息的动态生成)
```

**yaml**

```
spring:
kafka:
bootstrap-servers: '10.1.50.131:9092'
pangu:
chat:
kafka:
topic-center: 'topic.frame.center'
chat-clients:
pangu:
topics: 'topic.frame.client'
group: 'mainGroup'
clientCode: 'pgChatClientImpl'
emis:
topics: 'topic.emis.client'
group: 'mainGroup'
clientCode: 'pgChatClientImpl'
kafka:
servers: ${spring.kafka.bootstrap-servers}
retries: 1
batch-size: 16384
linger: 1
buffer-memory: 1024000
group-id: bootKafka
auto-commit: true
commit-interval: 100
session-timeout: 15000
topics:
pangu:
name: 'topic.frame.client'
num-partitions: 2
replication-factor: 2
panguCenter:
name: 'topic.emis.client'
num-partitions: 2
replication-factor: 2
```

```
ws中心端部署
    chat平台端模块为pangu-frame-chat-server，可直接部署于一个box之中,其配置文件如下
(pangu.kafka.topics 的配置用于主题信息的动态生成, auto-listener 下的为自动监听配置。
这里需要把所有客户端也配置进去，目前当作信息列表使用。后续有可能考虑自动发现)
```

**yaml**

```
spring:
kafka:
bootstrap-servers: '10.1.50.131:9092'
pangu:
kafka:
servers: ${spring.kafka.bootstrap-servers}
retries: 1
batch-size: 16384
linger: 1
buffer-memory: 1024000
group-id: bootKafka
auto-commit: true
commit-interval: 100
session-timeout: 15000
topics:
panguCenter:
name: 'topic.frame.center'
num-partitions: 2
replication-factor: 2
pangu:
name: 'topic.frame.client'
num-partitions: 2
replication-factor: 2
panguEmis:
name: 'topic.emis.client'
num-partitions: 2
replication-factor: 2
auto-listener:
enabled: true
auto-topics:
panguCenter:
topics: 'topic.frame.center'
group: 'mainGroup'
serviceCode: 'pgChatCenter'
ws:
enabled: true
host: 127.0.0.1
port: 8185
path: pangu-websocket
#下面这部分为wss需要开启，证书必须为权威认证，自生成的不行
ssl:
enabled: false
password: kingtang
key-store: 'classpath:server.keystore'
```

```
前端代码(执行必要的心跳机制及各个钩子回调)
```

**typescript**

```
import { Injectable } from'@angular/core';
import { WebsocketStorageService } from'@services/websocket-storage.service';
import { SettingsService } from'@services/settings.service';
import { PermissionService } from'@services/permission.service';
import { Router } from'@angular/router';
import { NzMessageService } from'_ng-zorro-antd@13.3.2@ng-zorro-antd/message';

@Injectable()
exportclassInitService {
constructor(
privatewsStorage:WebsocketStorageService,
privatesetting:SettingsService,
privatepermissionService:PermissionService,
privaterouter:Router,
privatemessage:NzMessageService
  ) {
if (window.location.pathname?.indexOf('micro-app') >=0) {
this.router.navigateByUrl('/layout', { skipLocationChange: false }).then((_) => {});
    }
  }

beatCount:number=0;

heartTimer:any;

initApp():Promise<any> {
returnnewPromise((resolve, _) => {
this.doSocketInIt();
resolve(null);
    });
  }

doSocketInIt() {
try {
if (typeof WebSocket ==='undefined') {
        console.log('您的浏览器不支持socket');
      } else {
// 实例化socket
// @ts-ignore
        window.pgSocket =newWebSocket(window.uriMgt.websocketUrl);
// 监听socket连接
// @ts-ignore
        window.pgSocket.onopen =this.onSocketOpen;
// 监听socket错误信息
// @ts-ignore
        window.pgSocket.onerror =this.onSocketError;
// 监听socket消息
// @ts-ignore
        window.pgSocket.onmessage= (ret:MessageEvent) => {
if (ret.data) {
constdata:any=JSON.parse(ret.data);
            console.log(data.msgStr);

switch (data.msgType) {
case1:
// @ts-ignore
                window.pgSocketKey = data.msgStr;
this.sendHeart();
this.beatCount =0;
break;
case2:
// 处理业务
break;
case3:
// 警告信息回调
this.message.warning(data.msgStr);
break;
case4:
if (this.beatCount >=1) {
this.beatCount--;
                }
break;
            }

this.wsStorage.socketCallBack.next(JSON.parse(ret.data));
          }

// // @ts-ignore
// window.pgSocket.send(
//   JSON.stringify({
//     // @ts-ignore
//     key: window.pgSocketKey,
//     msgType: 3,
//     msgStr: '业务测试！',
//   })
// );
        };
// @ts-ignore
        window.pgSocket.onclose= (ret:CloseEvent) => {
          console.log(ret);
if (this.heartTimer) {
clearInterval(this.heartTimer);
          }
this.beatCount =0;
        };
      }
    } catch (e:any) {
      console.error('websocket init fail');
    }
  }

sendHeart() {
this.heartTimer =setInterval(() => {
// 中间可能存在延迟过长导致计数器过大，而没减小的可能，但是忽略
if (this.beatCount >=4) {
        console.log('执行重连');
this.doSocketInIt();
      } else {
        console.log('ping'+this.beatCount);
// @ts-ignore
        window.pgSocket.send(
JSON.stringify({
            module: 'pangu',
            msgType: 4,
            msgStr: 'ping',
          })
        );
this.beatCount++;
      }
    }, 5000);
  }

onSocketOpen(ret:any) {
// @ts-ignore
    window.pgSocket.send(
JSON.stringify({
        module: 'pangu',
        msgType: 1,
        msgStr: {
// empId: 1,
        },
      })
    );
  }

onSocketError(ret:any) {
    console.log(ret);
  }
}
```

![image.png](http://pangu.kingtsoft.com/pangu-facade/assets/image1.b1f66964.png)

> #### 技术原理

```
组件交互图
```

![image.png](http://pangu.kingtsoft.com/pangu-facade/assets/image2.f652bd0d.jpg)

```
总共主要分为以下几个模块
```

> pangu-frame-chat chat业务引用模块（可以当客户端） pangu-frame-chat-common chat标准常量及数据结构 pangu-frame-chat-api chat门面接口 pangu-frame-chat-center chat中心端引用模块 pangu-frame-netty ws的封装 pangu-frame-chat-server 集成ws与chat中心端的服务 pangu-frame-simple-test 业务模块代表，象征业务

**pangu-frame-chat**

```
    主要封装了chat交互的具体实现，例如使用了kafka作为媒介
```

**pangu-frame-chat-common**

```
    主要封装了对chat模块的各类常量及数据结构PgChatEntity与PgChatCenterEntity
```

**pangu-frame-chat-api**

```
    主要封装了业务端各类操作所需门面api
```

**pangu-frame-chat-center**

```
    为服务中心端实现，在PgChatCenterTemplate中有个topicCode参数，此参数与配置
文件kafka部分的topics中的key保持一致。里面提供了通用执行程序的api pgChatCenterApi，
只要平台端实现这个api就可以将消息中的数据自动传送到指定的api方法。如下
```

**java**

```
package com.kingtsoft.pangu.frame.chat.server;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Component
public class  PgChatCenterHandlerimplementsPgChatCenterApi {

    @Override
private void   doProcess(PgChatCenterEntity pgChatCenterEntity) {
if (Objects.equals(pgChatCenterEntity.getMsgType(), PgChatConst.ChatCenterMsgType.TYPE_GROUP)) {
            WebSocketTemplate.sendWsMsgGroup(pgChatCenterEntity.getTopicCode(), pgChatCenterEntity.getContext());
return;
        }

        List<ChannelEntity> entityList =
                ChatChannelHandler.getChannelByMeta(
                        (allList, mapList) -> {
if (mapList ==null|| mapList.size() ==0) {
returnnew ArrayList<>(allList);
                            }
                            List<ChannelEntity> finList =new ArrayList<>();

for (Map<String, Object> map : mapList) {
for (ChannelEntity channelEntity : allList) {
                                    Map<String, Object> channelMeta = channelEntity.getMetaInfo();
if (channelMeta ==null) {
continue;
                                    }
if (!Objects.equals(channelEntity.getModule(), pgChatCenterEntity.getTopicCode())) {
continue;
                                    }

for (String key : map.keySet()) {
if (Objects.equals(channelMeta.get(key), map.get(key))) {
                                            finList.add(channelEntity);
break;
                                        }
                                    }
                                }
                            }

return finList;
                        }, pgChatCenterEntity.getMetaInfos());

for (ChannelEntity channelEntity : entityList) {
            WebSocketTemplate.sendWsMsg(channelEntity.getChannelId().aslong Text(), pgChatCenterEntity.getContext());
        }
    }
}
```

**pangu-frame-netty**

```
    此模块是针对ws具体实现的封装，支持WSS的的接入，但是经过测试，wss模式下无法使用私人生
成的证书。定义了数据结构ChatPojo与ChatBackPojo，前者为ws客户端发送信息到服务端的数据结
构，后者为服务端发送到客户端的数据结构。
    ChatPojo 中着重注意的为msgType，1-初始建立（用以互相保存相关信息，可以是业务关键信息，
例如empId,这样后续想通过empId进行发送的话就能以这些自定义信息为依据进行广播） 2-同组直接转
发（不经过业务后端，直接将信息转发给同模块下的客户端） 3-后端业务逻辑（通过消息去执行后端逻辑）
4-心跳检测。
四种类型核心代码如下
    客户端在建立连接后会执行一个额外的类型为1的信息（需要标记自身的module，与topic中的key
保持一致），用来告诉服务端对管道信息的保存及初始化，然后将初始化后的关键key发送给客户端进行
保存，后续的业务交互都需要附加这个key。
    查看private void   doProcess(ChannelHandlerContext ctx, String msgStr)可以
发现，在直连发送的情况之外的流程也就是msgType=2或3的情况都是由nettyProcessApi进行托管处理
```

**java**

```
package com.kingtsoft.pangu.frame.netty;

import com.alibaba.fastjson2.JSON;
import com.kingtsoft.pangu.base.exception.TipException;
import com.kingtsoft.pangu.frame.netty.constant.ChatConst;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;
import io.netty.handler.codec.http.FullHttpRequest;
import io.netty.handler.codec.http.websocketx.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.util.StringUtils;

/**
 * Title: <br>
 * Description: <br>
 * Company: wondersgroup.com <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Slf4j
public class  ChatWebSocketHandlerextendsSimpleChannelInboundHandler<WebSocketFrame> {

private final   NettyProcessApi nettyProcessApi;

publicChatWebSocketHandler(NettyProcessApi nettyProcessApi) {
this.nettyProcessApi = nettyProcessApi;
    }

    @Override
private void   channelActive(ChannelHandlerContext ctx) throws Exception {
        log.info("客户端连接：{}", ctx.channel().id());
super.channelActive(ctx);
    }

    @Override
private void   channelInactive(ChannelHandlerContext ctx) throws Exception {
        log.info("与客户端连接断开，通道关闭");
        ChatChannelHandler.removeChannel(ctx.channel().id());
super.channelInactive(ctx);
    }

    @Override
private void   channelReadComplete(ChannelHandlerContext ctx) {
        ctx.channel().flush();
    }

    @Override
protectedvoidchannelRead0(ChannelHandlerContext ctx, WebSocketFrame frame) {
if (frame instanceof PingWebSocketFrame) {
pingWebSocketFrameHandler(ctx, (PingWebSocketFrame) frame);
        } elseif (frame instanceof TextWebSocketFrame) {
textWebSocketFrameHandler(ctx, (TextWebSocketFrame) frame);
        } elseif (frame instanceof CloseWebSocketFrame) {
closeWebSocketFrameHandler(ctx, (CloseWebSocketFrame) frame);
        }
    }

    @Override
private void   channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
//首次连接是FullHttpRequest，处理参数
if (msg instanceof FullHttpRequest) {
            FullHttpRequest request = (FullHttpRequest) msg;
            String uri = request.uri();
            WebSocketTemplate.sendWsMsg(ctx.channel(), "汤小帅服务中心持续为您服务！");
        }

super.channelRead(ctx, msg);
    }

    /**
     * 客户端发送断开请求处理
     */
private void  closeWebSocketFrameHandler(ChannelHandlerContext ctx, CloseWebSocketFrame frame) {
        log.info("接收到主动断开请求：{}", ctx.channel().id());
        ctx.close();
    }

    /**
     * 创建连接之后，客户端发送的消息都会在这里处理
     */
private void  textWebSocketFrameHandler(ChannelHandlerContext ctx, TextWebSocketFrame frame) {
        String text = frame.text();
        ChatPoolUtil.POOL.execute(() ->doProcess(ctx, text));
    }

    /**
     * 处理客户端心跳包
     */
private void  pingWebSocketFrameHandler(ChannelHandlerContext ctx, PingWebSocketFrame frame) {
        ctx.channel().writeAndFlush(newPongWebSocketFrame(frame.content().retain()));
    }

private void  doProcess(ChannelHandlerContext ctx, String msgStr) {
        ChatPojo chatPojo;
try {
            chatPojo = JSON.parseObject(msgStr, ChatPojo.class);
        } catch (Exception e) {
thrownewTipException("未知的消息结构体！");
        }

if (nettyProcessApi ==null) {
thrownewTipException("无可用执行器！");
        }

switch (chatPojo.getMsgType()) {
case1:
                ChannelEntity channelEntity =newChannelEntity();
                channelEntity.setChannelId(ctx.channel().id());
                channelEntity.setModule(chatPojo.getModule());
                String meta = chatPojo.getMsgStr();
if (StringUtils.hasText(meta)) {
                    channelEntity.setMetaInfo(JSON.parseObject(meta));
                }

                String key = ChatChannelHandler.addChannelId(channelEntity, ctx.channel());
                WebSocketTemplate.sendWsMsg(ctx.channel(), key, ChatConst.BackType.TYPE_CONNECT);
break;
case2:
                nettyProcessApi.doSameGroup(ctx, chatPojo);
break;
case3:
                nettyProcessApi.doProcess(ctx, chatPojo);
break;
case4:
                WebSocketTemplate.sendWsMsg(ctx.channel(), "pong", ChatConst.BackType.TYPE_HEART_BEAT);
break;
default:
// 将客户端消息回送给客户端
                WebSocketTemplate.sendWsMsg(ctx.channel(), "你发送的内容是："+ chatPojo.getMsgStr());
        }
    }

}
```

```
   ChatBackPojo 中的msgType为1-建立连接回调 2-回复信息（常规信息回复用以业务处理） 3-警告信息|错误反馈
（因为要与常规信息区分，有时候服务端的ws信息可能操作会出现异常，这时候会用3这个状态将异常信息反馈，客户端可以
自己考虑后续操作，比如可以message.warn到页面）
    同样提供了一个api nettyProcessApi提供平台整个的时候对具体后端业务进行实现，如下，可以发现两个接口最后都是
走的消息，且消息的主题默认为topic.pangu.center-cluster，可以通过pangu.chat.kafka.topic-center进行
设置。这里的通过kafka实现的，所有继续往下找kafka
```

**java**

```
package com.kingtsoft.pangu.frame.chat.server;

import com.alibaba.fastjson2.JSON;
import com.kingtsoft.pangu.frame.chat.common.constant.PgChatConst;
import com.kingtsoft.pangu.frame.netty.*;
import io.netty.channel.ChannelHandlerContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.env.Environment;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageHeaders;
import org.springframework.messaging.support.GenericMessage;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Title: <br>
 * Description: <br>
 * Company: wondersgroup.com <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Slf4j
@Component
public class  NettyProcessHandlerimplementsNettyProcessApi {

privatestaticfinal Clock CLOCK = Clock.system(ZoneId.of("GMT+8"));

private final   KafkaTemplate<String, Object> kafkaTemplate;

private final   String topicCenter;

publicNettyProcessHandler(Environment environment,
                               KafkaTemplate<String, Object> kafkaTemplate) {
this.topicCenter = environment.getProperty("pangu.chat.kafka.topic-center", PgChatConst.PG_TOPIC_CHAT_CLUSTER);
this.kafkaTemplate = kafkaTemplate;
    }

    @Override
private void   doSameGroup(ChannelHandlerContext ctx, ChatPojo chatPojo) {
sendMsg(chatPojo, -1L);
    }

    /**
     * 业务内容接口
     *
     * @paramctx      管道上下文信息
     * @paramchatPojo 交互信息
     * @author 金炀
     */
    @Override
private void   doProcess(ChannelHandlerContext ctx, ChatPojo chatPojo) {
sendMsg(chatPojo, -1L);
    }

    /**
     * 发送信息
     *
     * @paramchatPojo 封装信息
     * @author 金炀
     */
private void  sendMsg(ChatPojo chatPojo, long  timeout) {
if (timeout ==-1L) {
            timeout =null;
        }
        Map<String, Object> map =new HashMap<>(8);
        map.put(KafkaHeaders.TOPIC, topicCenter);
        map.put(KafkaHeaders.KEY, createMsgKey());
        map.put(PgChatConst.ChatKafkaHeader.TIMEOUT, timeout);
        map.put(PgChatConst.ChatKafkaHeader.START_TIMESTAMP, CLOCK.millis());

try {
            Message<String> message =new GenericMessage<>(JSON.toJSONString(chatPojo), newMessageHeaders(map));
            kafkaTemplate.send(message);
        } catch (Exception e) {
            log.error("消息发送失败！", e);
        }
    }

publicstatic String createMsgKey() {
return UUID.randomUUID().toString().replace("-", "");
    }
}
```

```
    在chat-中心模块中，PgCenterClusterListenerImpl类是通过kafka的
配置化自动监听实现的，可以监听从netty模块中传播出来的业务处理信息，这么做
主要是用于解决分布式模式下的多实例，因为前端只会跟一台netty-server进行长
连接，而分布式模式下出于高可用及负载的考虑会存在多个实例，而此时需要通过每台
进行实例广播。我们通过消息广播实现了这个功能。
    这里默认也有一个timeout的处理，主要用于处理一些需要时效性的信息，可以
在发送的时候配置好头信息。这里会在接受到的时候自动丢弃
```

**java**

```
package com.kingtsoft.pangu.frame.chat.center.kafka;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Slf4j
@Component(PgChatConst.ChatKafkaServiceCode.CODE_CENTER_CLUSTER)
public class  PgCenterClusterListenerImplimplementsPgKafkaBatchMessageService {

privatestaticfinal Clock CLOCK = Clock.system(ZoneId.of("GMT+8"));

private final   PgChatCenterApi pgChatCenterApi;

publicPgCenterClusterListenerImpl(PgChatCenterApi pgChatCenterApi) {
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

if (record.headers() !=null) {
try {
                    Header header = record.headers().lastHeader(PgChatConst.ChatKafkaHeader.START_TIMESTAMP);
                    Header timeoutHeader = record.headers().lastHeader(PgChatConst.ChatKafkaHeader.TIMEOUT);

if (header !=null&& timeoutHeader !=null) {
long  startTimestamp = long .parselong (newString(header.value(), StandardCharsets.UTF_8));
long  timeout = long .parselong (newString(timeoutHeader.value(), StandardCharsets.UTF_8));

if (startTimestamp + timeout < CLOCK.millis()) {
continue;
                        }
                    }
                } catch (Exception ignore) {}
            }

try {
                pgChatCenterApi.doCenterProcess(message.get());
            } catch (Exception e) {
                log.error("chat中心执行失败！", e);
            }
        }
    }
}
```

```
  封装了WebSocketTemplate可以便捷通过keys key或者组或者channel本身等关键内容对消息进行发送。
封装了管道缓存类ChatChannelHandler，代码如下，主要对管道组及channel信息进行了保存。其中保存形
式以ChannelEntity为主，管道本身注册在了ChannelGroup中，同module中都使用同一个ChannelGroup
保存。这样就更加自由的发挥自带的ChannelGroup优势，可以对同组进行批量处理。其中getChannelByMeta
就是提供自定义数据过滤的方法，这样业务与chat组件之间就不会产生耦合。而具体过滤方法也使用了函数式编程
让平台去自实现，也解耦了平台逻辑与chat组件逻辑。
（此模块连接的ws，在2小时没有动静的情况下，会监测一下，如果没响应，则会自动断开）
```

**java**

```
package com.kingtsoft.pangu.frame.netty;

import io.netty.channel.Channel;
import io.netty.channel.ChannelId;
import io.netty.channel.group.ChannelGroup;
import io.netty.channel.group.ChannelMatchers;
import io.netty.channel.group.DefaultChannelGroup;
import io.netty.util.concurrent.GlobalEventExecutor;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang.com <br>
 *
 * @author 金炀
 * @version 1.0
 */
public class  ChatChannelHandler {

publicstatic Map<String, ChannelGroup> channelGroupMap =new ConcurrentHashMap<>(16);

publicstatic Map<String, ChannelEntity> channelInfoMap =new ConcurrentHashMap<>(32);

publicstatic String addChannelId(ChannelEntity channelEntity, Channel channel) {
        String key = channel.id().aslong Text();
// 处理通道组
if (channelGroupMap.get(channelEntity.getModule()) ==null) {
            ChannelGroup moduleGroup =newDefaultChannelGroup(GlobalEventExecutor.INSTANCE);
            moduleGroup.add(channel);
            channelGroupMap.put(channelEntity.getModule(), moduleGroup);
        } else {
            channelGroupMap.get(channelEntity.getModule()).add(channel);
        }

if (channelInfoMap.get(key) ==null) {
            channelInfoMap.put(key, channelEntity);
        } else {
// 说明有意料之外的管道信息，需要切断替换为新的
            ChannelGroup channelGroup = channelGroupMap.get(channelEntity.getModule());
if (channelGroup !=null) {
                Channel ch = channelGroup.find(channelInfoMap.get(key).getChannelId());
                channelGroup.disconnect(ChannelMatchers.is(ch));
                channelGroup.remove(ch);
            }

            channelInfoMap.put(key, channelEntity);
        }

return key;
    }

publicstaticvoidremoveChannel(ChannelId channelId) {
        ChannelEntity channelEntity = channelInfoMap.get(channelId.aslong Text());
if (channelEntity ==null) {
return;
        }

        channelInfoMap.remove(channelId.aslong Text());
        ChannelGroup channelGroup = channelGroupMap.get(channelEntity.getModule());
if (channelGroup ==null) {
return;
        }

        Channel ch = channelGroup.find(channelId);
if (ch ==null) {
return;
        }
        channelGroup.disconnect(ChannelMatchers.is(ch));
        channelGroup.remove(ch);
    }

publicstatic Channel getChannel(String key) {
        ChannelEntity channelEntity = channelInfoMap.get(key);
if (channelEntity ==null) {
returnnull;
        }

        ChannelGroup channelGroup = channelGroupMap.get(channelEntity.getModule());
if (channelGroup ==null) {
returnnull;
        }

return channelGroup.find(channelEntity.getChannelId());
    }

publicstatic Channel getChannel(ChannelId channelId) {
        AtomicReference<Channel> channel =new AtomicReference<>();

        channelGroupMap.forEach(
                (k, group) -> {
if (channel.get() ==null&& group.find(channelId) !=null) {
                        channel.set(group.find(channelId));
                    }
                }
        );

return channel.get();
    }

publicstatic ChannelGroup getChannelGroup(String key) {
        ChannelEntity channelEntity = channelInfoMap.get(key);
if (channelEntity ==null) {
returnnull;
        }

return channelGroupMap.get(channelEntity.getModule());
    }

publicstatic List<ChannelEntity> getChannelByMeta(ChatChannelFun chatChannelFun, List<Map<String, Object>> mapList) {
return chatChannelFun.getChannelEntity(channelInfoMap.values(), mapList);
    }
}
```

**pangu-frame-chat-server**

```
    模块主要整个netty模块及业务模块，netty中的ws是实现，而server模块则是整合这个实现与kafka，
通过kafka与业务沟通，kafka api与ws业务无关。所有这里就算以后整合额外的长连接方式也是支持的。
主要作用就是接收后端信息，并进行转发，而前端是ws业务，与netty是一对的，所以操作集成在netty里而
不是像后端一样集成在server端。
```

**pangu-frame-simple-test**

```
    这代表了业务模块，主要配置的是监听事件，需要引入的包如下
```

**xml**

```
<dependency>
    <groupId>com.kingtsoft.pangu</groupId>
    <artifactId>pangu-frame-chat-api</artifactId>
</dependency>
```

**pangu-frame-simple-test**所属启动器加入如下实现

**xml**

```
<dependency>
    <groupId>com.kingtsoft.pangu</groupId>
    <artifactId>pangu-frame-chat</artifactId>
</dependency>
```

```
    然后只需实现PgChatClientApi接口，即可直接实现数据监听回调监听,监听信息放入
在了配置文件内。所以将代码与具体实现进行了剥离。后续更换实现载体将不会影响倒业务代码。
```

**java**

```
package com.kingtsoft.pangu.frame.simple.test.listener;

import com.kingtsoft.pangu.frame.chat.api.PgChatClientApi;
import com.kingtsoft.pangu.frame.chat.api.PgChatTemplate;
import com.kingtsoft.pangu.frame.chat.common.PgChatEntity;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.List;
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
public class  PgChatClientImplimplementsPgChatClientApi {

private final   PgChatTemplate pgChatTemplate;

publicPgChatClientImpl(PgChatTemplate pgChatTemplate) {
this.pgChatTemplate = pgChatTemplate;
    }

    /**
     * 业务端消息信息处理
     *
     * @paramchatList 消息
     * @author 金炀
     */
    @Override
private void   doChatProcess(List<PgChatEntity> chatList) {
for (PgChatEntity pgChatEntity : chatList) {
try {
                System.out.println(pgChatEntity.getContext());

                Map<String, Object> m =new HashMap<>(4);
                m.put("empId", 1);
                pgChatTemplate.sendChat("pangu", "群发了", 1, m);
            } catch (Exception e) {
                log.error("日志业务端数据处理失败！", e);
            }
        }
    }
}
```

```
而业务中信息发送所需的为pgChatTemplate，直接注入即可。上图中,注释掉部分为信息发送，主要参数如下
    topicCode           	与之前平台端配置文件中pangu.kafka.topics中的key匹配
    context 			消息体，建议是业务自己统一的结构体
    msgType 		1-转发指定客户端 2-同组转发
    Map<String, Object> metaInfo 附加信息（一般用于过滤，比如我们要发送empId为1的客户端信息，
则如上图所示，加入入参即可。里面的数据在初始化时候客户端传入存储即可）
```
