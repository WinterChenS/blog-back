---
layout: post
title: springboot 中 @ConditionalOnExpression注解 在特定情况下使用相关配置或者实例化bean
date:  2018-05-30 09:20
comments: true
tags: [spring]
brief: "spring"
reward: true
categories: spring
cover: http://img.winterchen.com/alex-holyoake-388536-unsplash.jpg
---

![](http://img.winterchen.com/alex-holyoake-388536-unsplash.jpg)





在开发中会遇到一些需求：在配置文件中设置一个enable，当这个配置为true的时候，才进行相关的配置类的初始化。
<!-- more -->


示例：

需要实例化的bean，请不要加@Component注解

```java
public class TestBean {
  
  public TestBean(){
    
  }
  
  public doSomeThing(){
    
  }
}
```



配置类：

```java
@Configuration
@ConditionalOnExpression("${test.enabled:true}")
public class TestConfiguration {
    @Bean
    public TestBean testBean() {
        return new TestBean();
    }
}
```



配置文件：

```yaml
test.enabled: true
```

这个bean只有在`test.enabled: true`的时候才会进行初始化。
