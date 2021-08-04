---
layout: post
title: Spring boot Mybatis 整合（注解版）
date:  2018-01-18 21:40
comments: true
tags: [Spring Boot, mybatis]
brief: "Spring boot 入门"
reward: true
categories: Spring Boot
keywords: springboot, mybatis,java
cover: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039845.jpg
image: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039845.jpg
---

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039845.jpg)

>   之前写过一篇关于springboot 与 mybatis整合的博文，使用了一段时间[spring-data-jpa](http://winterchen.com/2017/11/11/springbootdata2/)，发现那种方式真的是太爽了，mybatis的xml的映射配置总觉得有点麻烦。接口定义和映射离散在不同的文件中，阅读起来不是很方便。于是，准备使用mybatis的注解方式实现映射。如果喜欢xml方式的可以看我之前的博文：[ Spring boot Mybatis 整合（完整版）](http://blog.csdn.net/winter_chen001/article/details/77249029)
<!--  more  -->
### 源码

请前往文章末端查看


### 开发环境：
***
* 开发工具：Intellij IDEA 2017.1.3
* JDK : 1.8.0_101
* spring boot 版本 ： 1.5.8.RELEASE
* maven : 3.3.9

### 拓展：
* springboot 整合 Mybatis 事务管理


### 开始

#### 1.新建一个springboot项目：
![这里写图片描述](http://img.blog.csdn.net/20171124094443907?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvV2ludGVyX2NoZW4wMDE=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

![这里写图片描述](http://img.blog.csdn.net/20171124094505295?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvV2ludGVyX2NoZW4wMDE=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

**添加依赖**
![这里写图片描述](http://img.blog.csdn.net/20171124094516207?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvV2ludGVyX2NoZW4wMDE=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

#### 2.看一下项目结构

![这里写图片描述](http://img.blog.csdn.net/20171124094524448?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvV2ludGVyX2NoZW4wMDE=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)


#### 3.完整依赖

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>

	<groupId>com.winterchen</groupId>
	<artifactId>springboot-mybatis-demo2</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<packaging>jar</packaging>

	<name>springboot-mybatis-demo2</name>
	<description>Demo project for Spring Boot</description>

	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>1.5.8.RELEASE</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>

	<properties>
		<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
		<project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
		<java.version>1.8</java.version>
	</properties>

	<dependencies>
		<dependency>
			<groupId>org.mybatis.spring.boot</groupId>
			<artifactId>mybatis-spring-boot-starter</artifactId>
			<version>1.3.1</version>
		</dependency>

		<dependency>
			<groupId>mysql</groupId>
			<artifactId>mysql-connector-java</artifactId>
			<scope>runtime</scope>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
		</dependency>
	</dependencies>

	<build>
		<plugins>
			<plugin>
				<groupId>org.springframework.boot</groupId>
				<artifactId>spring-boot-maven-plugin</artifactId>
			</plugin>
		</plugins>
	</build>


</project>

```


#### 4.配置文件
因为习惯性的喜欢使用yml作为配置文件，所以将application.properties替换为application.yml

```yml
spring:
  datasource:
     url: jdbc:mysql://127.0.0.1:3306/mytest
     username: root
     password: root
     driver-class-name: com.mysql.jdbc.Driver
```

简单且简洁的完成了基本配置，下面看看我们是如何在这个基础下轻松使用Mybatis访问数据库的

### 使用Mybatis
***
* 在Mysql数据库中创建数据表：
```sql
CREATE DATABASE mytest;

USE mytest;

CREATE TABLE t_user(
  id BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL ,
  password VARCHAR(255) NOT NULL ,
  phone VARCHAR(255) NOT NULL
) ENGINE=INNODB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8;

```

* 创建映射对象User
```java
package com.winterchen.domain;

/**
 * User实体映射类
 * Created by Administrator on 2017/11/24.
 */

public class User {

    private Integer id;
    private String name;
    private String password;
    private String phone;

	//省略 get 和 set ...
}

```

* 创建User映射的操作UserMapper，为了后续单元测试验证，实现插入和查询操作

```java
package com.winterchen.mapper;

import com.winterchen.domain.User;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * User映射类
 * Created by Administrator on 2017/11/24.
 */
@Mapper
public interface UserMapper {

    @Select("SELECT * FROM T_USER WHERE PHONE = #{phone}")
    User findUserByPhone(@Param("phone") String phone);

    @Insert("INSERT INTO T_USER(NAME, PASSWORD, PHONE) VALUES(#{name}, #{password}, #{phone})")
    int insert(@Param("name") String name, @Param("password") String password, @Param("phone") String phone);

}


```

**如果想了解更多Mybatis注解的详细：[springboot中使用Mybatis注解配置详解](http://blog.csdn.net/winter_chen001/article/details/78623700)**

* 创建springboot 主类：
```java
package com.winterchen;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SpringbootMybatisDemo2Application {

	public static void main(String[] args) {
		SpringApplication.run(SpringbootMybatisDemo2Application.class, args);
	}
}

```

* 创建测试单元:
	* 测试逻辑：插入一条name为"weinterchen"的User，然后根据user的phone进行查询，并判断user的name是否为"winterchen"。

```java
package com.winterchen;

import com.winterchen.domain.User;
import com.winterchen.mapper.UserMapper;
import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@SpringBootTest
public class SpringbootMybatisDemo2ApplicationTests {


	@Autowired
	private UserMapper userMapper;

	@Test
	public void test(){

		userMapper.insert("winterchen", "123456", "12345678910");
		User u = userMapper.findUserByPhone("12345678910");
		Assert.assertEquals("winterchen", u.getName());
	}

	

}

```


* 测试结果

![这里写图片描述](http://img.blog.csdn.net/20171124103725302?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvV2ludGVyX2NoZW4wMDE=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

说明已经成功了


### 事务管理（重要）
***
> 我们在开发企业应用时，对于业务人员的一个操作实际是对数据读写的多步操作的结合。由于数据操作在顺序执行的过程中，任何一步操作都有可能发生异常，异常会导致后续操作无法完成，此时由于业务逻辑并未正确的完成，之前成功操作数据的并不可靠，需要在这种情况下进行回退。


**为了测试的成功，请把测试的内容进行替换，因为之前测试的时候已经将数据生成了，重复的数据会对测试的结果有影响**

```java
	@Test
	@Transactional
	public void test(){

		userMapper.insert("张三", "123456", "18600000000");
		int a = 1/0;
		userMapper.insert("李四", "123456", "13500000000");
		User u = userMapper.findUserByPhone("12345678910");
		Assert.assertEquals("winterchen", u.getName());
	}
```

只需要在需要事务管理的方法上添加 `@Transactional` 注解即可，然后我们启动测试，会发现异常之后，数据库中没有产生数据。

如果大家想对springboot事务管理有更加详细的了解，欢迎大家查看：[ springboot事务管理详解](http://blog.csdn.net/Winter_chen001/article/details/78622679)


源码：https://github.com/WinterChenS/springboot-mybatis-demo2/