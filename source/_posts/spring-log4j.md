---
layout: post
title: Spring中使用log4j详细配置
date: 2017-09-26 16:39
comments: true
tags: [spring,log4j]
brief: "记一下"
reward: true
categories: spring
keywords: spring,log4j,java
cover: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039846.jpg
image: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039846.jpg
---

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039846.jpg)
第一步：导入log4j-1.2.17.jar包。
第二步：src同级创建并设置log4j.properties。
	log4j.properties的详细配置：
<!-- more -->
```properties
 ### 设置 ###
log4j.rootLogger = debug,stdout,D,E

### 输出信息到控制抬 ###
log4j.appender.stdout = org.apache.log4j.ConsoleAppender
log4j.appender.stdout.Target = System.out
log4j.appender.stdout.layout = org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern = [%-5p] %d{yyyy-MM-dd HH:mm:ss,SSS} method:%l%n%m%n

### 输出DEBUG 级别以上的日志到=E://logs/error.log ###
log4j.appender.D = org.apache.log4j.DailyRollingFileAppender
log4j.appender.D.File = E://logs/log.log
log4j.appender.D.Append = true
log4j.appender.D.Threshold = DEBUG 
log4j.appender.D.layout = org.apache.log4j.PatternLayout
log4j.appender.D.layout.ConversionPattern = %-d{yyyy-MM-dd HH:mm:ss}  [ %t:%r ] - [ %p ]  %m%n

### 输出ERROR 级别以上的日志到=E://logs/error.log ###
log4j.appender.E = org.apache.log4j.DailyRollingFileAppender
log4j.appender.E.File =E://logs/error.log 
log4j.appender.E.Append = true
log4j.appender.E.Threshold = ERROR 
log4j.appender.E.layout = org.apache.log4j.PatternLayout
log4j.appender.E.layout.ConversionPattern = %-d{yyyy-MM-dd HH:mm:ss}  [ %t:%r ] - [ %p ]  %m%n
```

[更详细的log4j.properties配置](http://blog.csdn.net/qq_30175203/article/details/52084127)

第三步：web.xml中加入配置详细：

```xml
<!-- 设置根目录 -->  
<!--初始化log4j.properties-->
   <context-param>  
    <param-name>log4jConfigLocation</param-name>  
    <param-value>/WEB-INF/classes/log4j.properties</param-value>  
</context-param>  
<!-- 3000表示 开一条watchdog线程每60秒扫描一下配置文件的变化;这样便于日志存放位置的改变 -->  
<context-param>    
        <param-name>log4jRefreshInterval</param-name>    
        <param-value>3000</param-value>    
   </context-param>   
<listener>  
    <listener-class>org.springframework.web.util.Log4jConfigListener</listener-class>  
</listener>
```


applicationContext.xml就不需要配置了

```xml
<?xml version="1.0" encoding="UTF-8"?>  
<beans xmlns="http://www.springframework.org/schema/beans"  
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:context="http://www.springframework.org/schema/context"  
    xmlns:aop="http://www.springframework.org/schema/aop"  
    xsi:schemaLocation="    

http://www.springframework.org/schema/beans


http://www.springframework.org/schema/beans/spring-beans-3.2.xsd


http://www.springframework.org/schema/aop


http://www.springframework.org/schema/aop/spring-aop-3.2.xsd


http://www.springframework.org/schema/context

           http://www.springframework.org/schema/context/spring-context-3.2.xsd">  
</beans>
```

然后日志就可以随着spring的启动而启动了。

如果想把日志文件打印到Tomcat日志文件中：
log4j.appender.R.File=${catalina.home}/logs/youLogFile.log 

这个方法只能Tomcat使用，其它容器就不行了。

