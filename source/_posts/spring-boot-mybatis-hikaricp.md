---
layout: post
title: springboot整合mybatis 使用HikariCP连接池
date:  2018-07-25 15:49
comments: true
tags: [Spring Boot, mybatis, HikariCP]
brief: "Spring boot 入门"
reward: true
categories: Spring Boot
cover: http://img.winterchen.com/IMG_2333.jpg
---

## 前言

Springboot让Java开发更加美好，本节主要讲的是使用Hikari数据库连接池，如果需要使用druid连接池的请看我另外一篇博客，[springboot Mybatis 整合](https://blog.csdn.net/winter_chen001/article/details/80010967)（这篇文章有详细搭建springboot项目的过程，对于刚接触springboot的新手有帮助）。

### 为什么使用HikariCP

在Springboot2.X版本，数据库的连接池官方推荐使用[HikariCP](https://github.com/brettwooldridge/HikariCP)，官方的原话：

>  Production database connections can also be auto-configured by using a pooling`DataSource`. Spring Boot uses the following algorithm for choosing a specific implementation:
> 
> 1. We prefer[HikariCP](https://github.com/brettwooldridge/HikariCP)for its performance and concurrency. If HikariCP is available, we always choose it.
> 
> 2. Otherwise, if the Tomcat pooling`DataSource`is available, we use it.
> 
> 3. If neither HikariCP nor the Tomcat pooling datasource are available and if[Commons DBCP2](https://commons.apache.org/proper/commons-dbcp/)is available, we use it.

意思是说：

1. 我们更喜欢HikariCP的性能和并发性。如果有HikariCP，我们总是选择它

2. 否则，如果Tomcat池数据源可用，我们将使用它。

3. 如果HikariCP和Tomcat池数据源都不可用，如果Commons DBCP2可用，我们将使用它。

那么如何使用HikariCP呢？

如果你的springboot版本是2.X，当你使用`spring-boot-starter-jdbc`或者`spring-boot-starter-data-jpa`依赖，springboot就会自动引入HikariCP的依赖了。

### 使用指定的数据库连接池

如果你需要使用指定的数据库连接池，那么你需要在`application.properties`中配置：`spring.datasource.type`



## 环境

* JDK： 1.8

* Maven: 3.3.9

* SpringBoot: 2.0.3.RELEASE

* 开发工具：Intellij IDEA 2017.1.3



## 开始使用

本次的配置中我们持久层使用mybatis，使用HikariCP作为数据库连接池。

### 引入依赖

```xml
        <dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-jdbc</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
			<exclusions>
				<!--排除默认的tomcat-jdbc-->
				<exclusion>
					<groupId>org.apache.tomcat</groupId>
					<artifactId>tomcat-jdbc</artifactId>
				</exclusion>
			</exclusions>
		</dependency>
		<dependency>
			<groupId>mysql</groupId>
			<artifactId>mysql-connector-java</artifactId>
			<version>5.1.46</version>
		</dependency>
		<!-- mybatis一定要使用starter，不然无法自动配置和注入 -->
		<dependency>
			<groupId>org.mybatis.spring.boot</groupId>
			<artifactId>mybatis-spring-boot-starter</artifactId>
			<version>1.3.2</version>
		</dependency>

		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-test</artifactId>
			<scope>test</scope>
		</dependency>        
```

以上的依赖就足够了，前面介绍过，只需要导入`spring-boot-starter-jdbc`依赖springboot就默认使用Hikari作为数据库连接池了。

### 创建数据表

```sql
CREATE DATABASE mytest;

CREATE TABLE t_user(
  userId INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  userName VARCHAR(255) NOT NULL ,
  password VARCHAR(255) NOT NULL ,
  phone VARCHAR(255) NOT NULL
) ENGINE=INNODB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8;
```



### 创建实体类

```java
package com.winterchen.model;

/**
 * Created by Donghua.Chen on 2018/7/25.
 */
public class UserDomain {

    private Integer userId;

    private String userName;

    private String password;

    private String phone;

    // @TODO 省略get/set
}

```



### 创建Dao以及mapper映射

#### 创建Dao类

创建一个dao的包，并且在这个包下创建一个UserDao

```java
package com.winterchen.dao;

import com.winterchen.model.UserDomain;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * Created by Donghua.Chen on 2018/7/25.
 */
@Mapper
public interface UserDao {

    int insert(UserDomain record);

    void deleteUserById(@Param("userId") Integer userId);

    void updateUser(UserDomain userDomain);

    List<UserDomain> selectUsers();

}
```

注意：一定不要忘了使用`@Mapper`注解，如果没有这个注解，spring就无法扫描到这个类，导致项目启动报错。



#### 创建Mapper映射

上一步我们创建dao数据库持久层类，由于本文使用的是xml映射的方式，所以我们需要创建一个xml映射文件。

在`resources`文件夹下新建一个文件夹`mapper`：

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd" >
<mapper namespace="com.winterchen.dao.UserDao" >
    <sql id="BASE_TABLE">
        t_user
    </sql>

    <sql id="BASE_COLUMN">
        userId,userName,password,phone
    </sql>

    <insert id="insert" parameterType="com.winterchen.model.UserDomain">
        INSERT INTO
        <include refid="BASE_TABLE"/>
        <trim prefix="(" suffix=")" suffixOverrides=",">
            userName,password,
            <if test="phone != null">
                phone,
            </if>
        </trim>
        <trim prefix="VALUES(" suffix=")" suffixOverrides=",">
            #{userName, jdbcType=VARCHAR},#{password, jdbcType=VARCHAR},
            <if test="phone != null">
                #{phone, jdbcType=VARCHAR},
            </if>
        </trim>
    </insert>

    <delete id="deleteUserById">
      DELETE FROM
      <include refid="BASE_TABLE"/>
      WHERE
      userId = #{userId, jdbcType=INTEGER}
    </delete>
    <!-- 更新用户信息，为空的字段不进行置空 -->
    <update id="updateUser" parameterType="com.winterchen.model.UserDomain">
        UPDATE
        <include refid="BASE_TABLE"/>
        <set>
          <if test="userName != null">
              userName = #{userName, jdbcType=VARCHAR},
          </if>
          <if test="password != null">
              password = #{password, jdbcType=VARCHAR},
          </if>
          <if test="phone != null">
              phone = #{phone, jdbcType=VARCHAR},
          </if>
        </set>
        <where>
            userId = #{userId, jdbcType=INTEGER}
        </where>
    </update>

    <select id="selectUsers" resultType="com.winterchen.model.UserDomain">
        SELECT
        <include refid="BASE_COLUMN"/>
        FROM
        <include refid="BASE_TABLE"/>
    </select>
</mapper>
```

**注意点：** 请将`namespace="com.winterchen.dao.UserDao"`改为你自己项目Dao的路径，以及下面方法的一些路径都要改为你自己项目的相关路径。



### 配置

```
server.port=8080

#### 数据库连接池属性
spring.datasource.driver-class-name=com.mysql.jdbc.Driver
spring.datasource.url=jdbc:mysql://127.0.0.1:3306/mytest?useSSL=false&useUnicode=true&characterEncoding=utf-8&allowMultiQueries=true
spring.datasource.username=root
spring.datasource.password=root
#自动提交
spring.datasource.default-auto-commit=true
#指定updates是否自动提交
spring.datasource.auto-commit=true
spring.datasource.maximum-pool-size=100
spring.datasource.max-idle=10
spring.datasource.max-wait=10000
spring.datasource.min-idle=5
spring.datasource.initial-size=5
spring.datasource.validation-query=SELECT 1
spring.datasource.test-on-borrow=false
spring.datasource.test-while-idle=true
# 配置间隔多久才进行一次检测，检测需要关闭的空闲连接，单位是毫秒
spring.datasource.time-between-eviction-runs-millis=18800
# 配置一个连接在池中最小生存的时间，单位是毫秒
spring.datasource.minEvictableIdleTimeMillis=300000

# mybatis对应的映射文件路径
mybatis.mapper-locations=classpath:mapper/*.xml
# mybatis对应的实体类
mybatis.type-aliases-package=com.winterchen.model
```



### Service层

```java
package com.winterchen.service;

import com.winterchen.model.UserDomain;

import java.util.List;

/**
 * Created by Donghua.Chen on 2018/7/25.
 */
public interface UserService {

    int insert(UserDomain record);

    void deleteUserById(Integer userId);

    void updateUser(UserDomain userDomain);

    List<UserDomain> selectUsers();

}

```

### Service 实现层

```java
package com.winterchen.service.impl;

import com.winterchen.dao.UserDao;
import com.winterchen.model.UserDomain;
import com.winterchen.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Created by Donghua.Chen on 2018/7/25.
 */
@Service
public class UserServiceImpl implements UserService {

    @Autowired
    private UserDao userDao;//这里会爆红，请忽略

    @Override
    public int insert(UserDomain record) {
        return userDao.insert(record);
    }

    @Override
    public void deleteUserById(Integer userId) {
        userDao.deleteUserById(userId);
    }

    @Override
    public void updateUser(UserDomain userDomain) {
        userDao.updateUser(userDomain);
    }

    @Override
    public List<UserDomain> selectUsers() {
        return userDao.selectUsers();
    }
}

```



### Controller层

```java
package com.winterchen.controller;

import com.winterchen.model.UserDomain;
import com.winterchen.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Created by Donghua.Chen on 2018/7/25.
 */
@RestController
@RequestMapping("/user")
public class UserController {

    @Autowired
    private UserService userService;

    @PostMapping("")
    public ResponseEntity addUser(
            @RequestParam(value = "userName", required = true)
            String userName,
            @RequestParam(value = "password", required = true)
            String password,
            @RequestParam(value = "phone", required = false)
            String phone
    ){
        UserDomain userDomain = new UserDomain();
        userDomain.setUserName(userName);
        userDomain.setPassword(password);
        userDomain.setPhone(phone);
        userService.insert(userDomain);
        return ResponseEntity.ok("添加成功");
    }

    @DeleteMapping("")
    public ResponseEntity deleteUser(@RequestParam(value = "userId", required = true) Integer userId){

        userService.deleteUserById(userId);
        return ResponseEntity.ok("删除成功");
    }

    @PutMapping("")
    public ResponseEntity updateUser(
            @RequestParam(value = "userId", required = true)
                    Integer userId,
            @RequestParam(value = "userName", required = false)
                    String userName,
            @RequestParam(value = "password", required = false)
                    String password,
            @RequestParam(value = "phone", required = false)
                    String phone
    ){
        UserDomain userDomain = new UserDomain();
        userDomain.setUserId(userId);
        userDomain.setUserName(userName);
        userDomain.setPassword(password);
        userDomain.setPhone(phone);
        userService.updateUser(userDomain);
        return ResponseEntity.ok("更新成功");
    }

    @GetMapping("")
    public ResponseEntity getUsers(){
        return ResponseEntity.ok(userService.selectUsers());
    }
}
```

强行科普一下：

* `@RequestParam ` 用于将请求参数区数据映射到功能处理方法的参数上，`value`：参数名字，即入参的请求参数名字，如userName表示请求的参数区中的名字为userName的参数的值将传入，`required`：是否必须，默认是true，表示请求中一定要有相应的参数，否则将报404错误码；

* [@Controller和@RestController的区别？](https://www.cnblogs.com/shuaifing/p/8119664.html)



### 启动类

```java
package com.winterchen;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class SpringBootMybatisHikaricpApplication {

	public static void main(String[] args) {
		SpringApplication.run(SpringBootMybatisHikaricpApplication.class, args);
	}
}
```



### 最终项目结构

![目录结构](http://img.winterchen.com/WX20180725-151516@2x.png)



## 启动



启动项目启动类

```
2018-07-25 15:25:42.970  INFO 22602 --- [           main] o.s.w.s.handler.SimpleUrlHandlerMapping  : Mapped URL path [/**] onto handler of type [class org.springframework.web.servlet.resource.ResourceHttpRequestHandler]
2018-07-25 15:25:43.380  INFO 22602 --- [           main] o.s.j.e.a.AnnotationMBeanExporter        : Registering beans for JMX exposure on startup
2018-07-25 15:25:43.382  INFO 22602 --- [           main] o.s.j.e.a.AnnotationMBeanExporter        : Bean with name 'dataSource' has been autodetected for JMX exposure
2018-07-25 15:25:43.389  INFO 22602 --- [           main] o.s.j.e.a.AnnotationMBeanExporter        : Located MBean 'dataSource': registering with JMX server as MBean [com.zaxxer.hikari:name=dataSource,type=HikariDataSource]
2018-07-25 15:25:43.450  INFO 22602 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
2018-07-25 15:25:43.456  INFO 22602 --- [           main] c.w.SpringBootMybatisHikaricpApplication : Started SpringBootMybatisHikaricpApplication in 6.267 seconds (JVM running for 7.784)
```

这样的输出表示项目启动成功了！！如果遇到报错启动不了，请回头看看是不是有些地方没有注意到。



## 测试

项目成功启动了，那么可以开始测试了

推荐使用一个强大的http请求工具：Postman

### 添加

![添加](http://img.winterchen.com/WX20180725-142118@2x.png)

### 删除

![删除](http://img.winterchen.com/WX20180725-141938@2x.png)

### 更新

![更新](http://img.winterchen.com/WX20180725-142044@2x.png)



### 查找

![查找](http://img.winterchen.com/WX20180725-141808@2x.png)





## 最后

>  在编程的路上肯定会遇到很多的bug，程序员就是要不断的和bug作斗争，加油，愿你成为真正的大牛。有机会讲讲Hikari如何使用多数据源。



源码地址：[戳这里](https://github.com/WinterChenS/springboot-learning-experience/tree/master/spring-boot-mybatis-hikaricp)



springboot技术交流群：681513531

个人博客：[https://winterchen.com](https://winterchen.com/)




