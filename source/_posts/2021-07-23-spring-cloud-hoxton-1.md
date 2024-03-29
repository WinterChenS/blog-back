---
layout: post
title: SpringCloud系列教程开篇
date: 2021-07-23 16:55
top: 0
comments: true
tags: [springcloud]
brief: [share]
reward: true
categories: springcloud
keywords: springcloud
cover: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046759529456.jpg
image: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046760324597.jpg
---


SpringCloud 作为目前最热门的技术之一，拥有众多的开发者的爱戴，开箱即用，简单配置的特性让开发者只需要关注业务代码的开发，无需在繁琐和架构中挣扎。SpringCloud也成为了java开发人员必须了解和使用的技能。

作为系列的开篇，全系列会介绍hoxton的正式版如何使用，也会对一些组件的原理进行介绍，并且会结合实战中的使用着重讲一讲。本文也会照顾初学者，一些详细的配置会深入浅出。

## 大纲

- 为什么要学习Spring Cloud
- 什么是Spring Cloud
- 优缺点
- 需要的版本
- 组件的介绍
- 实战中的应用介绍

## 为什么要学习springcloud

不论是商业应用还是用户应用，在业务初期都很简单，我们通常会把它实现为单体结构的应用。但是，随着业务逐渐发展，产品思想会变得越来越复杂，单体结构的应用也会越来越复杂。这就会给应用带来如下的几个问题：

- 代码结构混乱：业务复杂，导致代码量很大，管理会越来越困难。同时，这也会给业务的快速迭代带来巨大挑战；
- 开发效率变低：开发人员同时开发一套代码，很难避免代码冲突。开发过程会伴随着不断解决冲突的过程，这会严重的影响开发效率；
- 排查解决问题成本高：线上业务发现 bug，修复 bug 的过程可能很简单。但是，由于只有一套代码，需要重新编译、打包、上线，成本很高。

由于单体结构的应用随着系统复杂度的增高，会暴露出各种各样的问题。近些年来，微服务架构逐渐取代了单体架构，且这种趋势将会越来越流行。Spring Cloud是目前最常用的微服务开发框架，已经在企业级开发中大量的应用。

## 什么是Spring Cloud

Spring Cloud是一系列框架的有序集合。它利用Spring Boot的开发便利性巧妙地简化了分布式系统基础设施的开发，如服务发现注册、配置中心、智能路由、消息总线、负载均衡、断路器、数据监控等，都可以用Spring Boot的开发风格做到一键启动和部署。Spring Cloud并没有重复制造轮子，它只是将各家公司开发的比较成熟、经得起实际考验的服务框架组合起来，通过Spring Boot风格进行再封装屏蔽掉了复杂的配置和实现原理，最终给开发者留出了一套简单易懂、易部署和易维护的分布式系统开发工具包。

## 优缺点

### 优点：

- 产出于Spring大家族，Spring在企业级开发框架中无人能敌，来头很大，可以保证后续的更新、完善
- 组件丰富，功能齐全。Spring Cloud 为微服务架构提供了非常完整的支持。例如、配置管理、服务发现、断路器、微服务网关等；
- Spring Cloud 社区活跃度很高，教程很丰富，遇到问题很容易找到解决方案
- 服务拆分粒度更细，耦合度比较低，有利于资源重复利用，有利于提高开发效率
- 可以更精准的制定优化服务方案，提高系统的可维护性
- 减轻团队的成本，可以并行开发，不用关注其他人怎么开发，先关注自己的开发
- 微服务可以是跨平台的，可以用任何一种语言开发
- 适于互联网时代，产品迭代周期更短

### 缺点：

- 微服务过多，治理成本高，不利于维护系统
- 分布式系统开发的成本高(容错，分布式事务等)对团队挑战大

总的来说优点大过于缺点，目前看来Spring Cloud是一套非常完善的分布式框架，目前很多企业开始用微服务、Spring Cloud的优势是显而易见的。因此对于想研究微服务架构的同学来说，学习Spring Cloud是一个不错的选择。

## 版本

本次教程以Hoxton最新的RELEASE版本进行整合。

### 为什么使用Hoxton版本？

因为springboot作为springcloud底层基础设施，所以springcloud与springboot版本需要正确的兼容，不然会在整合的过程中出现很多的问题，各种`class not found`，`method not found`。回到问题本身，为什么要使用hoxton版本，那是因为直到目前为止，官方更新的稳定版只有hoxton.release，在生产环境中，最好要使用release版本。

### 那么初学者如何快速找到合适的版本呢？

当然是查看[官方文档](https://spring.io/projects/spring-cloud)了

| Release Train                                                                                          | Boot Version                          |
|--------------------------------------------------------------------------------------------------------|---------------------------------------|
| https://github.com/spring-cloud/spring-cloud-release/wiki/Spring-Cloud-2020.0-Release-Notes aka Ilford | 2.4.x, 2.5.x (Starting with 2020.0.3) |
| https://github.com/spring-cloud/spring-cloud-release/wiki/Spring-Cloud-Hoxton-Release-Notes            | 2.2.x, 2.3.x (Starting with SR5)      |
| https://github.com/spring-projects/spring-cloud/wiki/Spring-Cloud-Greenwich-Release-Notes              | 2.1.x                                 |
| https://github.com/spring-projects/spring-cloud/wiki/Spring-Cloud-Finchley-Release-Notes               | 2.0.x                                 |
| https://github.com/spring-projects/spring-cloud/wiki/Spring-Cloud-Edgware-Release-Notes                | 1.5.x                                 |
| https://github.com/spring-projects/spring-cloud/wiki/Spring-Cloud-Dalston-Release-Notes                | 1.5.x                                 |


![springcloud版本](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046454878575.png)

由此可以看出最新的稳定版。

## 组件的介绍

springcloud家族有着众多的组件，不可能所有的组件都是我们适用的，需要结合业务选择合适的组件使用，其他的组件可以了解一下，后面的教程会结合目前比较热门的方案进行整合使用，下面的表是比较热门的组件介绍：

| 组件名                                          | 功能               | 简介                          |
|----------------------------------------------|------------------|-----------------------------|
| spring-cloud-starter-alibaba-nacos-config    | 配置中心             | 阿里巴巴开源的nacos配置中心，简单易用，稳定可靠。 |
| spring-cloud-starter-alibaba-nacos-discovery | 服务注册与发现（注册中心）    | 阿里巴巴开源的nacox注册中心，非常稳定，速度快。  |
| spring-cloud-openfeign                       | 服务远程调用，服务熔断，负载均衡 |                             |
| spring-cloud-gateway                         | 服务网关             | 负责服务的路由，限流，权限验证，请求过滤        |
| spring-cloud-starter-alibaba-sentinel        | 服务限流             | 阿里巴巴开源                      |
| spring-cloud-starter-alibaba-seata           | 分布式事务组件          | 阿里巴巴开源                      |


其它的组件后续会继续讲解。

## 实战中的应用

先看一张技术架构图：

![spring cloud 技术架构图](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046455117574.png)

假设现在有一个请求过来，

- 第一站到达gateway网关，gateway负责请求的路由（请求到具体的服务节点），限流权限验证（登录，权限），请求过滤；
- 第二站，路由到了具体的服务，比如用户中心，用户中心调用课程管理中心接口，课程管理中心服务有很多节点，具体选择哪个节点呢？这时候需要服务的负载均衡，ribbon根据具体的策略进行服务的负载。
- 如果请求课程管理中心服务的节点超时异常，那么feign集成的hystrix负责服务的熔断，如果不熔断会导致请求阻塞，请求一直积压，最终会导致整个服务器集群宕机，有了服务熔断机制，当服务不可用的时候会将节点设置为不可用状态，并将请求打到其它可用节点，后续会轮询该节点，如果可用会恢复到可用状态。

## 总结

讲到了为何使用springcloud以及基础组件的介绍，后续会更加深入的讲解组件的使用。

搭建源码地址：[WinterChenS/spring-cloud-hoxton-study](https://github.com/WinterChenS/spring-cloud-hoxton-study)


### 参考文档：

[Spring Cloud](https://spring.io/projects/spring-cloud)

[Spring Cloud Hoxton Release Notes · spring-cloud/spring-cloud-release Wiki](https://github.com/spring-cloud/spring-cloud-release/wiki/Spring-Cloud-Hoxton-Release-Notes)

[springcloud 版本](https://blog.csdn.net/weixin_39786341/article/details/111392364)