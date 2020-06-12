---
layout: post
title: springboot2.0 Mybatis 整合 (springboot2.0版本)
date:  2018-04-21 00:57
comments: true
tags: [Spring Boot,mybatis]
brief: "Spring Boot"
reward: true
categories: Spring Boot
cover: http://img.winterchen.com/simon-abrams-286276-unsplash.jpg
---
![](http://img.winterchen.com/simon-abrams-286276-unsplash.jpg)




> springboot终于迎来了2.0版本，很多新的特性让springboot更加强大，之前[使用1.5.6版本整合了Mybatis](https://blog.csdn.net/winter_chen001/article/details/77249029)，现在2.0版本就已经不适用了，所以，在摸索中搭建了2.0版本整合Mybatis
<!-- more -->

## 写在前面
本来这篇博文老在就写好了，但是后来发现很多功能其实根本就没有检验通过就发出来了，导致遗留了很多坑，比如最难搞的就是SqlSessionFactory和PageHelper，之前写过关于springboot1.5.6版本的整合，这段时间刚好springboot发布了2.0的正式版本，很多同学可能没有注意版本，导致了整合的时候出现了很多很多的问题，这几天刚好有空就试着整合一下springboot2.0 mybatis，发现了很多很多的坑，而且网上的资源也不多，终于在两天的踩坑中成功整合了，并且将翻页功能修复好了，废话不多说了，看代码：

## 环境/版本一览：

* 开发工具：Intellij IDEA 2017.1.3
* springboot: **2.0.1.RELEASE**
* jdk：1.8.0_40
* maven:3.3.9
* alibaba Druid 数据库连接池：1.1.0

### 额外功能：

* PageHelper 分页插件
* mybatis generator 自动生成代码插件（本次搭建就不讲解了，请参照[Spring boot Mybatis 整合（完整版）](https://blog.csdn.net/winter_chen001/article/details/77249029)）

## 开始搭建：

### 创建项目：

![](http://img.winterchen.com/WX20180419-171728@2x.png)

![](http://img.winterchen.com/WX20180419-172151@2x.png)

添加基础的依赖：
![](http://img.winterchen.com/WX20180419-172335@2x.png)


### 依赖文件：
按照pom文件补齐需要的依赖：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>

	<groupId>com.winterchen</groupId>
	<artifactId>springboot2-mybatis-demo</artifactId>
	<version>0.0.1-SNAPSHOT</version>
	<packaging>jar</packaging>

	<name>springboot2-mybatis-demo</name>
	<description>Demo project for Spring Boot</description>

	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>2.0.1.RELEASE</version>
		<relativePath/> <!-- lookup parent from repository -->
	</parent>

	<properties>
		<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
		<project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
		<java.version>1.8</java.version>
	</properties>

	<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
		</dependency>
		<dependency>
			<groupId>org.mybatis.spring.boot</groupId>
			<artifactId>mybatis-spring-boot-starter</artifactId>
			<version>1.3.2</version>
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
		<dependency>
			<groupId>org.apache.commons</groupId>
			<artifactId>commons-lang3</artifactId>
			<version>3.4</version>
		</dependency>


		<dependency>
			<groupId>com.fasterxml.jackson.core</groupId>
			<artifactId>jackson-core</artifactId>
		</dependency>
		<dependency>
			<groupId>com.fasterxml.jackson.core</groupId>
			<artifactId>jackson-databind</artifactId>
		</dependency>
		<dependency>
			<groupId>com.fasterxml.jackson.datatype</groupId>
			<artifactId>jackson-datatype-joda</artifactId>
		</dependency>
		<dependency>
			<groupId>com.fasterxml.jackson.module</groupId>
			<artifactId>jackson-module-parameter-names</artifactId>
		</dependency>
		<!-- 分页插件 -->
		<dependency>
			<groupId>com.github.pagehelper</groupId>
			<artifactId>pagehelper</artifactId>
			<version>5.1.3</version>
		</dependency>
		<!-- alibaba的druid数据库连接池 -->
		<dependency>
			<groupId>com.alibaba</groupId>
			<artifactId>druid-spring-boot-starter</artifactId>
			<version>1.1.0</version>
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

### 项目结构：

![项目结构](http://img.winterchen.com/WX20180419-172817@2x.png)

#### 项目启动类：

```java
package com.winterchen;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Springboot2MybatisDemoApplication {

	public static void main(String[] args) {
		SpringApplication.run(Springboot2MybatisDemoApplication.class, args);
	}
}

```

### 配置：

> 可以根据个人使用习惯选择使用``properties``或者``yml``文件，本项目使用的是yml配置文件，所以把原本``application.properties``删除，创建一个``application.yml``文件


在resource文件夹下创建``application.yml``

```yaml
server:
  port: 8080


spring:
    datasource:
        name: test
        url: jdbc:mysql://127.0.0.1:3306/mytest?useUnicode=true&characterEncoding=UTF-8&allowMultiQueries=true
        username: root
        password: root
        # 使用druid数据源
        type: com.alibaba.druid.pool.DruidDataSource
        driver-class-name: com.mysql.jdbc.Driver
        filters: stat
        maxActive: 20
        initialSize: 1
        maxWait: 60000
        minIdle: 1
        timeBetweenEvictionRunsMillis: 60000
        minEvictableIdleTimeMillis: 300000
        validationQuery: select 'x'
        testWhileIdle: true
        testOnBorrow: false
        testOnReturn: false
        poolPreparedStatements: true
        maxPoolPreparedStatementPerConnectionSize: 20
        maxOpenPreparedStatements: 20
        
mybatis:
  mapper-locations: classpath:mapper/*.xml
  type-aliases-package: com.winterchen.model

mapper:
  mappers:  com.winterchen.dao
  not-empty: false
  identity: MYSQL

#pagehelper
pagehelper:
    helperDialect: mysql
    reasonable: true
    supportMethodsArguments: true
    params: count=countSql
    returnPageInfo: check


```

### 创建包：
``model``，``dao``，``mapper``,``config``

![](http://img.winterchen.com/WX20180419-193448@2x.png)

### 新建配置类：


``PageHelperConfig.java``

> 以下配置非常的重要，``PageHelper``的Page拦截器``PageInterceptor ``，如果不进行配置，那么分页功能将没有效果

```java
package com.winterchen.config;

import com.github.pagehelper.PageInterceptor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Properties;

/**
 * 分页插件的配置
 * Created by Donghua.Chen on 2018/4/20.
 */
@Configuration
public class PageHelperConfig {


    @Value("${pagehelper.helperDialect}")
    private String helperDialect;
    

    @Bean
    public PageInterceptor pageInterceptor(){
        PageInterceptor pageInterceptor = new PageInterceptor();
        Properties properties = new Properties();
        properties.setProperty("helperDialect", helperDialect);
        pageInterceptor.setProperties(properties);
        return pageInterceptor;
    }
}


```


``DataSourceConfig.java``

> 在springboot2.0版本，如果不定义``SqlSessionFactory``，那么将会导致错误，因为无法注入``SqlSessionFactory``，**并且下面注释部分的内容非常的重要，这也是整合当中遇到的很大的坑，如果不将PageInterceptor作为插件设置到SqlSessionFactoryBean中，导致分页失效**

```java
package com.winterchen.config;

import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInterceptor;
import org.apache.ibatis.plugin.Interceptor;
import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.SqlSessionFactoryBean;
import org.mybatis.spring.annotation.MapperScan;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.sql.DataSource;

/**
 * 2018/4/19 18:46
 */
@Configuration
@MapperScan("com.winterchen.dao")
@EnableTransactionManagement
public class DataSourceConfig {


    private static Logger logger = LoggerFactory.getLogger(DataSourceConfig.class);

    @Autowired
    private Environment env;

    @Autowired
    private PageInterceptor pageInterceptor;

    @Bean
    public SqlSessionFactory sqlSessionFactory(DataSource dataSource) throws Exception {
        SqlSessionFactoryBean fb = new SqlSessionFactoryBean();
        fb.setDataSource(dataSource);
        //该配置非常的重要，如果不将PageInterceptor设置到SqlSessionFactoryBean中，导致分页失效
        fb.setPlugins(new Interceptor[]{pageInterceptor});
        fb.setTypeAliasesPackage(env.getProperty("mybatis.type-aliases-package"));
        fb.setMapperLocations(new PathMatchingResourcePatternResolver().getResources(env.getProperty("mybatis.mapper-locations")));
        return fb.getObject();
    }
}
```

``DruidDBConfig.java``
> 在Spring Boot1.4.0中驱动配置信息没有问题，但是连接池的配置信息不再支持这里的配置项，即无法通过配置项直接支持相应的连接池；这里列出的这些配置项可以通过定制化DataSource来实现。
  目前Spring Boot中默认支持的连接池有dbcp,dbcp2, tomcat, hikari三种连接池。 

由于Druid暂时不在Spring Bootz中的直接支持，故需要进行配置信息的定制：

```java
package com.winterchen.config;

import com.alibaba.druid.pool.DruidDataSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import javax.sql.DataSource;
import java.sql.SQLException;

/**
 * Created by Donghua.Chen on 2018/4/19.
 */
@Configuration
public class DruidDBConfig {
    private Logger logger = LoggerFactory.getLogger(DruidDBConfig.class);

    @Value("${spring.datasource.url}")
    private String dbUrl;

    @Value("${spring.datasource.username}")
    private String username;

    @Value("${spring.datasource.password}")
    private String password;

    @Value("${spring.datasource.driver-class-name}")
    private String driverClassName;

    @Value("${spring.datasource.initialSize}")
    private int initialSize;

    @Value("${spring.datasource.minIdle}")
    private int minIdle;

    @Value("${spring.datasource.maxActive}")
    private int maxActive;

    @Value("${spring.datasource.maxWait}")
    private int maxWait;

    @Value("${spring.datasource.timeBetweenEvictionRunsMillis}")
    private int timeBetweenEvictionRunsMillis;

    @Value("${spring.datasource.minEvictableIdleTimeMillis}")
    private int minEvictableIdleTimeMillis;

    @Value("${spring.datasource.validationQuery}")
    private String validationQuery;

    @Value("${spring.datasource.testWhileIdle}")
    private boolean testWhileIdle;

    @Value("${spring.datasource.testOnBorrow}")
    private boolean testOnBorrow;

    @Value("${spring.datasource.testOnReturn}")
    private boolean testOnReturn;

    @Value("${spring.datasource.poolPreparedStatements}")
    private boolean poolPreparedStatements;

    @Value("${spring.datasource.maxPoolPreparedStatementPerConnectionSize}")
    private int maxPoolPreparedStatementPerConnectionSize;

    @Value("${spring.datasource.filters}")
    private String filters;

    @Value("{spring.datasource.connectionProperties}")
    private String connectionProperties;

    @Bean     //声明其为Bean实例
    @Primary  //在同样的DataSource中，首先使用被标注的DataSource
    public DataSource dataSource(){
        DruidDataSource datasource = new DruidDataSource();

        datasource.setUrl(this.dbUrl);
        datasource.setUsername(username);
        datasource.setPassword(password);
        datasource.setDriverClassName(driverClassName);

        //configuration
        datasource.setInitialSize(initialSize);
        datasource.setMinIdle(minIdle);
        datasource.setMaxActive(maxActive);
        datasource.setMaxWait(maxWait);
        datasource.setTimeBetweenEvictionRunsMillis(timeBetweenEvictionRunsMillis);
        datasource.setMinEvictableIdleTimeMillis(minEvictableIdleTimeMillis);
        datasource.setValidationQuery(validationQuery);
        datasource.setTestWhileIdle(testWhileIdle);
        datasource.setTestOnBorrow(testOnBorrow);
        datasource.setTestOnReturn(testOnReturn);
        datasource.setPoolPreparedStatements(poolPreparedStatements);
        datasource.setMaxPoolPreparedStatementPerConnectionSize(maxPoolPreparedStatementPerConnectionSize);
        try {
            datasource.setFilters(filters);
        } catch (SQLException e) {
            logger.error("druid configuration initialization filter", e);
        }
        datasource.setConnectionProperties(connectionProperties);

        return datasource;
    }
}
```




### 创建数据库和数据表

```sql
CREATE DATABASE mytest;

CREATE TABLE t_user(
  userId INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  userName VARCHAR(255) NOT NULL ,
  password VARCHAR(255) NOT NULL ,
  phone VARCHAR(255) NOT NULL
) ENGINE=INNODB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8;
```

### 创建实体类：``UserDomain.java``

```java
package com.winterchen.model;

public class UserDomain {
    private Integer userId;

    private String userName;

    private String password;

    private String phone;

    // get,set方法略...
}
```


### 创建dao：

``UserDao.java``

```java
package com.winterchen.dao;



import com.winterchen.model.UserDomain;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

public interface UserDao {


    int insert(UserDomain record);



    List<UserDomain> selectUsers();
}
```
### 创建mybatis映射文件： ``UserMapper.xml``

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

  <select id="selectUsers" resultType="com.winterchen.model.UserDomain">
      SELECT
        <include refid="BASE_COLUMN"/>
      FROM
        <include refid="BASE_TABLE"/>
  </select>


</mapper>
```

### 创建剩余的``controller``，``service``包和文件

``UserService.java``

```java
package com.winterchen.service.user;

import com.winterchen.model.UserDomain;

import java.util.List;

/**
 * Created by Administrator on 2018/4/19.
 */
public interface UserService {

    int addUser(UserDomain user);

    List<UserDomain> findAllUser(int pageNum, int pageSize);
}

```

``UserServiceImpl``

```java
package com.winterchen.service.user.impl;

import com.github.pagehelper.PageHelper;
import com.winterchen.dao.UserDao;
import com.winterchen.model.UserDomain;
import com.winterchen.service.user.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Created by Administrator on 2017/8/16.
 */
@Service(value = "userService")
public class UserServiceImpl implements UserService {

    @Autowired
    private UserDao userDao;//这里会报错，但是并不会影响

    @Override
    public int addUser(UserDomain user) {

        return userDao.insert(user);
    }

    /*
    * 这个方法中用到了我们开头配置依赖的分页插件pagehelper
    * 很简单，只需要在service层传入参数，然后将参数传递给一个插件的一个静态方法即可；
    * pageNum 开始页数
    * pageSize 每页显示的数据条数
    * */
    @Override
    public List<UserDomain> findAllUser(int pageNum, int pageSize) {
        //将参数传给这个方法就可以实现物理分页了，非常简单。
        PageHelper.startPage(pageNum, pageSize);
        return userDao.selectUsers();
    }
}

```
``UserController.java``

```java
package com.winterchen.controller;

import com.github.pagehelper.PageHelper;
import com.winterchen.model.UserDomain;
import com.winterchen.service.user.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

/**
 * Created by Administrator on 2017/8/16.
 */
@Controller
@RequestMapping(value = "/user")
public class UserController {

    @Autowired
    private UserService userService;

    @ResponseBody
    @PostMapping("/add")
    public int addUser(UserDomain user){
        return userService.addUser(user);
    }

    @ResponseBody
    @GetMapping("/all")
    public Object findAllUser(
            @RequestParam(name = "pageNum", required = false, defaultValue = "1")
                    int pageNum,
            @RequestParam(name = "pageSize", required = false, defaultValue = "10")
                    int pageSize){
        //开始分页
        PageHelper.startPage(pageNum,pageSize);
        return userService.findAllUser(pageNum,pageSize);
    }
}

```

## 项目最终的结构

![项目结构](http://img.winterchen.com/WX20180420-210845@2x.png)

> 到这里如果项目就成功搭建完成了，如果还是报错的话，请仔细看看配置，后面会给出源码地址，程序员就是要不断和bug进行斗争，加油。



## 测试

启动项目

![启动项目](http://img.winterchen.com/WX20180419-204915@2x.png)


这样就表示启动成功了

然后，开始测试吧，博主使用的是postMan，一个进行http请求的测试工具

### 添加数据

![添加数据](http://img.winterchen.com/WX20180419-205055@2x.png)


### 查询数据

![查询数据](http://img.winterchen.com/WX20180419-205209@2x.png)

源码地址：

[https://github.com/WinterChenS/springboot2-mybatis-demo](https://github.com/WinterChenS/springboot2-mybatis-demo)

如果遇到问题可以加我wechat：


<img src="http://img.winterchen.com/Wechat.jpg" width = "200" height = "200" alt="wechat"/>


















    
    
    




