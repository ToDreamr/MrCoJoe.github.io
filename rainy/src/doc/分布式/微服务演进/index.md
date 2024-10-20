---
title: "NetFlix和SpringCloudAlibaba"
date: 2024-01-26T13:56:23
tags : ["微服务"]
draft : false
---

<h3>Spring Cloud Netflix 介绍</h3>
<p>Netflix套件中有<code>Eureka</code>、<code>Ribbon</code>、<code>Hystrix</code>、<code>Zuul</code>、<code>Feign</code>五个非常知名的开源项目，分别被用于<code>服务治理</code>、<code>负载均衡</code>、<code>服务容错</code>、<code>服务网关</code>、<code>服务通信</code>。</p>
<p>2018年，Netflix套件中的开源项目陆续进入了维护模式。</p>
<p>2020年12月22日，Spring Cloud 2020.0.0版本发布，该版本中移除了Netflix套件中的相关依赖。</p>
<h3 id="toc-1">Spring Cloud Alibaba 介绍</h3>
<p>2018年7月，Spring Cloud Alibaba正式开源，进入Spring Cloud孵化器。2018年10月，Spring Cloud Alibaba发布开源后的第一个版本。</p>
<p>Spring Cloud Alibaba提供的组件如下：</p>
<ul>
<li><code>Sentinel</code>：阿里巴巴开源产品，不仅仅可以作为断路器，也支持流量控制和服务降级。</li>
<li><code>Nacos</code>：阿里巴巴开源产品，服务注册与服务发现，同时也可以作为配置中心。</li>
<li><code>RocketMQ</code>：阿里巴巴开源的分布式消息和流计算平台。</li>
<li><code>Dubbo</code>：阿里巴巴开源产品，高性能Java RPC框架，服务通信组件。</li>
<li><code>Seata</code>：阿里巴巴开源产品，一个易于使用的高性能微服务分布式事务解决方案。</li>
<li><code>Alibaba Cloud ACM</code>：其前身为淘宝内部配置中心Diamond，是一款应用配置中心产品，需付费。</li>
<li><code>Alibaba Cloud OSS</code>：阿里云对象存储OSS是一款海量、安全、低成本、高可靠的云存储服务，需付费。</li>
<li><code>Alibaba Cloud SMS</code>：阿里云短信服务，需付费。</li>
<li><code>Alibaba Cloud SchedulerX</code>：阿里中间件自研的基于Akka架构的新一代分布式任务调度平台，需付费。</li>
</ul>
<h3 id="toc-2">spring-cloud 和 spring-cloud-alibaba 的区别</h3>
<ul>
<li><code>Spring Cloud</code>：Spring 官方提供的分布式应用开发的一套共用模式，也可以理解成一套微服务开发的统一的抽象编程模型。</li>
<li><code>Spring Cloud Netflix</code>：基于 Spring Cloud 编程模型实现的微服务框架，是最早期的微服务框架。近年来，Netflix 宣布大多数组件停止维护。</li>
<li><code>Spring Cloud Alibaba</code>：Alibaba 提供的基于 Spring Cloud 编程模型实现的微服务框架，其所有组件都来自于阿里巴巴微服务技术，无论是解决方案完整性、技术成熟度、社区还是文档资料等都对国内开发者非常友好。</li>
</ul>
<p><code>spring-cloud</code>是<code>Spring</code>官方提供的微服务开发工具。它基于<code>Spring Boot</code>构建，提供了一系列框架和工具帮助我们快速构建分布式系统中的微服务架构。<code>spring-cloud</code>主要包含以下组件:</p>
<ul>
<li><code>Eureka</code>:服务注册中心,用于服务注册与发现。</li>
<li><code>Ribbon</code>:负载均衡器,在服务调用方进行负载均衡。</li>
<li><code>Feign</code>:声明式 REST 客户端,简化 RESTful API 的调用。</li>
<li><code>Hystrix</code>:熔断器,容错管理工具,防止分布式系统中级联故障。</li>
<li><code>Config</code>:配置中心,通过 Git 仓库统一管理应用配置。</li>
<li><code>Bus</code>:事件总线,用于广播配置文件变更事件。</li>
<li><code>Sleuth</code>:调用链监控系统,用于跟踪微服务中的调用链信息。</li>
<li><code>Stream</code>:消息驱动微服务,简化消息系统的使用。</li>
<li><code>Zuul</code>:API 网关,用于认证、监控和路由转发等功能。</li>
<li><code>Gateway</code>:新的 API 网关,取代 Zuul。</li>
</ul>
<p>除此之外，<code>spring-cloud</code>还支持与第三方组件的整合，如:</p>
<ul>
<li><code>Kubernetes</code>:容器编排平台的整合。</li>
<li><code>Netflix组件</code>:Ribbon、Hystrix、Zuul 等。</li>
<li><code>Zookeeper</code>:服务注册发现与配置中心的支持。</li>
<li><code>Consul</code>:服务注册发现与配置中心的支持。</li>
</ul>
<p><code>spring-cloud-alibaba</code>是阿里巴巴开源的组件，主要包含了阿里巴巴在微服务方面的若干开源产品，<code>spring-cloud-alibaba</code>中的主要组件有:</p>
<ul>
<li><code>Nacos</code>:一个更易于构建云原生应用的动态服务发现、配置管理和服务管理平台。</li>
<li><code>Dubbo</code>:阿里巴巴开源的一个高性能 Java RPC 框架。</li>
<li><code>RocketMQ</code>:一款开源的分布式消息系统,基于高可用分布式集群技术,提供低延时的、高可靠的消息发布与订阅服务。</li>
<li><code>Seata</code>:阿里巴巴开源产品,一个易于使用的高性能微服务分布式事务解决方案。</li>
<li><code>Sentinel</code>:阿里巴巴开源产品,一个控制微服务流量的开源框架。</li>
</ul>
<p>除此之外，<code>spring-cloud-alibaba</code>还整合了<code>Spring Cloud</code>与上述组件，提供了更加完善的微服务解决方案，主要包含:</p>
<ul>
<li><code>Service Discovery</code>:包含 Nacos 与 Eureka 的发现组件。</li>
<li><code>Configuration</code>:Nacos 配置中心组件。</li>
<li><code>Messaging</code>:RocketMQ 消息中间件的整合。</li>
<li><code>Distributed Transaction</code>:Seata 的分布式事务支持。</li>
<li><code>Circuit Breaker</code>:Sentinel 的熔断与限流支持。</li>
<li><code>Gateway</code>:与 Spring Cloud Gateway 的整合。</li>
</ul>
<blockquote>
<p>Spring Cloud Dubbo 从 2021.0.1.0 起已被移除出主干，不再随主干演进。</p>
</blockquote>
