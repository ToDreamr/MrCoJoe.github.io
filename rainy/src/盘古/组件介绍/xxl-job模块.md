# xxl-job模块

> #### 如何使用

```
项目引入如下模块
```

**xml**

```
<dependency>
  <groupId>com.kingtsoft.pangu</groupId>
  <artifactId>pangu-spring-xxl</artifactId>
</dependency>
```

```
配置文件
```

**yaml**

```
# xxl-job
xxl:
job:
admin:
### 调度中心部署根地址 [选填]：如调度中心集群部署存在多个地址则用逗号分隔。执行器将会使用该地址进行"执行器心跳注册"和"任务结果回调"；为空则关闭自动注册；
addresses: 'http://10.1.50.131:8887/xxl-job-admin'
### 执行器通讯TOKEN [选填]：非空时启用；
accessToken: default_token
executor:
### 执行器AppName [选填]：执行器心跳注册分组依据；为空则关闭自动注册
appname: xxl-job-executor-pangu
### 执行器注册 [选填]：优先使用该配置作为注册地址，为空时使用内嵌服务 ”IP:PORT“ 作为注册地址。从而更灵活的支持容器类型执行器动态IP和动态映射端口问题。
address:
### 执行器IP [选填]：默认为空表示自动获取IP，多网卡时可手动设置指定IP，该IP不会绑定Host仅作为通讯实用；地址信息用于 "执行器注册" 和 "调度中心请求并触发任务"；
ip:
### 执行器端口号 [选填]：小于等于0则自动获取；默认端口为9999，单机部署多个执行器时，注意要配置不同执行器端口；
port: 9999
### 执行器运行日志文件存储磁盘路径 [选填] ：需要对该路径拥有读写权限；为空则使用默认路径；
logpath: ${user.home}/logs/pangu/xxl/jobhandler
### 执行器日志文件保存天数 [选填] ： 过期日志自动清理, 限制值大于等于3时生效; 否则, 如-1, 关闭自动清理功能；
logretentiondays: 30
```

> #### 技术原理

```
这个模块并未做太多封装，初始化了执行器配置，内如下。
```

**java**

```
package com.kingtsoft.pangu.spring.xxl;

import com.xxl.job.core.executor.impl.XxlJobSpringExecutor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Title: <br>
 * Description: <br>
 * Company: KingTang <br>
 *
 * @author 金炀
 * @version 1.0
 */
@Slf4j
@Configuration
public class  XxlJobAutoConfiguration {

    @Value("${xxl.job.admin.addresses}")
private String adminAddresses;

    @Value("${xxl.job.accessToken}")
private String accessToken;

    @Value("${xxl.job.executor.appname}")
private String appname;

    @Value("${xxl.job.executor.address}")
private String address;

    @Value("${xxl.job.executor.ip}")
private String ip;

    @Value("${xxl.job.executor.port}")
privateint port;

    @Value("${xxl.job.executor.logpath}")
private String logPath;

    @Value("${xxl.job.executor.logretentiondays}")
privateint logRetentionDays;

    @Bean
public XxlJobSpringExecutor xxlJobExecutor() {
        log.info(">>>>>>>>>>> xxl-job config init.");
        XxlJobSpringExecutor xxlJobSpringExecutor =newXxlJobSpringExecutor();
        xxlJobSpringExecutor.setAdminAddresses(adminAddresses);
        xxlJobSpringExecutor.setAppname(appname);
        xxlJobSpringExecutor.setAddress(address);
        xxlJobSpringExecutor.setIp(ip);
        xxlJobSpringExecutor.setPort(port);
        xxlJobSpringExecutor.setAccessToken(accessToken);
        xxlJobSpringExecutor.setLogPath(logPath);
        xxlJobSpringExecutor.setLogRetentionDays(logRetentionDays);

return xxlJobSpringExecutor;
    }
}
```
