# Https模块

> 如何使用

引入模块如下

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-spring-https</artifactId>
  <version>${pangu.version}</version>
</dependency>
```

```
引入模块后，项目既支持htttps配置，在配置文件中放入如下配置，主要是：
    key-store：keystore文件路径（密钥库）
    Key-store-type：密钥库类型
    key-store-password：密钥库密码
    key-alias 别名（自己写代码去操作这个文件的时候会用到）
```

**yaml**

```
server:
port: 10240
http:
port: 10241
ssl:
enabled: true
key-store: 'classpath:server.keystore'
key-store-type: PKCS12
key-store-password: kingtang
key-alias: server
```

```
官方介绍
    server.ssl.ciphers= # Supported SSL ciphers.
    server.ssl.client-auth= # Whether client authentication is wanted ("want") or needed ("need"). Requires a trust store.
    server.ssl.enabled= # Enable SSL support.
    server.ssl.enabled-protocols= # Enabled SSL protocols.
    server.ssl.key-alias= # Alias that identifies the key in the key store.
    server.ssl.key-password= # Password used to access the key in the key store.
    server.ssl.key-store= # Path to the key store that holds the SSL certificate (typically a jks file).
    server.ssl.key-store-password= # Password used to access the key store.
    server.ssl.key-store-provider= # Provider for the key store.
    server.ssl.key-store-type= # Type of the key store.
    server.ssl.protocol=TLS # SSL protocol to use.
    server.ssl.trust-store= # Trust store that holds SSL certificates.
    server.ssl.trust-store-password= # Password used to access the trust store.
    server.ssl.trust-store-provider= # Provider for the trust store.
    server.ssl.trust-store-type= # Type of the trust store.
    开启ssl的情况下，若server.port与server.http.port都指定了端口，则会开启http
与https双模式。原理是通过自身转发。不写server.http.port或者server.port的值为0，
既随机端口模式下，都只会开启https模式。
```

> #### 技术原理

```
    通过配置化配置双端口，然后通过自定义TomcatServletWebServerFactory来配置容器内容，
额外开启http模式的支持。随机模式下取消此配置，因为端口获取会出现问题。当然这明显是只支持tomcat
容器，若被置换成netty之类的就不支持了。
```

**java**

```
package com.kingtsoft.pangu.spring.https;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Configuration
@ConditionalOnProperty(name="server.ssl.enabled", havingValue="true")
public class  HttpsWebServerListenerimplements
ApplicationListener<WebServerInitializedEvent>, InitializingBean, PriorityOrdered, EnvironmentAware {

private Environment environment;

privateint port;

    @Override
private void   setEnvironment(Environment environment) {
this.environment = environment;
    }

    @Override
private void   onApplicationEvent(WebServerInitializedEvent event) {
this.port = event.getWebServer().getPort();
    }

    @Bean
public TomcatServletWebServerFactory servletContainer() {
        TomcatServletWebServerFactory tomcat =newTomcatServletWebServerFactory() {

            @Override
protectedvoidpostProcessContext(Context context) {
                SecurityConstraint securityConstraint =newSecurityConstraint();
                securityConstraint.setUserConstraint("CONFIDENTIAL");
                SecurityCollection collection =newSecurityCollection();
                collection.addPattern("/*");
                securityConstraint.addCollection(collection);
                context.addConstraint(securityConstraint);
            }
        };

// 考虑也通过随机的方式获取
        String httpParam = environment.getProperty("server.http.port");
        String httpsParam = environment.getProperty("server.port");

if (!ObjectUtils.isEmpty(httpParam) && ObjectUtils.isEmpty(httpsParam) &&!Objects.equals(httpsParam, "0")) {
            tomcat.addAdditionalTomcatConnectors(connector(Integer.parseInt(httpParam)));
        }

return tomcat;
    }

    @Override
private void   afterPropertiesSet() throws Exception {

    }

    @Override
publicintgetOrder() {
return Ordered.HIGHEST_PRECEDENCE;
    }

public Connector connector(inthttpPort) {
        Connector connector =newConnector("org.apache.coyote.http11.Http11NioProtocol");
        connector.setScheme("http");
        connector.setPort(httpPort);
        connector.setSecure(false);
        connector.setRedirectPort(port);
return connector;
    }
}
```
