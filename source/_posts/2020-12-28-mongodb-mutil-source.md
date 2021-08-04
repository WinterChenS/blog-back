---
layout: post
title: mongodb多数据源之mongotemplate和事务的配置
date: 2020-12-28 15:55
top: 0
comments: true
tags: [mongodb, mongotemplate, springboot,transactional]
brief: [share]
reward: true
categories: mongodb
keywords: mongodb, mongotemplate, springboot,transactional
cover: http://img.winterchen.com/20201228155223.jpg
image: http://img.winterchen.com/20201228155223.jpg
---


> 题图：我的家乡，拍摄于2020年初疫情期间

## maven坐标

```xml
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-mongodb</artifactId>
            <version>2.1.13.RELEASE</version>
        </dependency>
```

## 多数据源配置

配置文件：

```yaml
spring:
  data:
    mongodb:
      uri: mongodb://192.168.150.154:17017
      database: ewell-label
    mongodb-target:
      uri: mongodb://192.168.150.154:17017
      database: ewell-label-target
```

java配置：

主数据源：

```java
package com.winterchen.label.service.configuration;

import com.mongodb.MongoClient;
import com.mongodb.MongoClientURI;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.mongodb.MongoDbFactory;
import org.springframework.data.mongodb.MongoTransactionManager;
import org.springframework.data.mongodb.config.AbstractMongoConfiguration;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.SimpleMongoDbFactory;
import org.springframework.data.mongodb.core.convert.DefaultDbRefResolver;
import org.springframework.data.mongodb.core.convert.DefaultMongoTypeMapper;
import org.springframework.data.mongodb.core.convert.MappingMongoConverter;
import org.springframework.data.mongodb.core.mapping.MongoMappingContext;

/**
 * @author winterchen
 * @version 1.0
 * @date 2020/12/2 3:51 下午
 * @description 业务mongo数据源
 **/
@Configuration
public class BusinessMongoConfig extends AbstractMongoConfiguration {

    @Value("${spring.data.mongodb.uri}")
    private String uri;

    @Value("${spring.data.mongodb.database}")
    private String database;

    @Override
    protected String getDatabaseName() {
        return database;
    }

    @Override
    public MongoClient mongoClient() {
        MongoClientURI mongoClientURI = new MongoClientURI(uri);
        return new MongoClient(mongoClientURI);
    }

    @Primary
    @Bean("mongoMappingContext")
    public MongoMappingContext mongoMappingContext() {
        MongoMappingContext mappingContext = new MongoMappingContext();
        return mappingContext;
    }

    @Primary
    @Bean
    public MongoTransactionManager transactionManager(@Qualifier("mongoDbFactory") MongoDbFactory mongoDbFactory) throws Exception {
        return new MongoTransactionManager(mongoDbFactory);
    }

    @Primary
    @Bean("mongoDbFactory")
    public MongoDbFactory mongoDbFactory() {
        return new SimpleMongoDbFactory(mongoClient(), getDatabaseName());
    }

    @Primary
    @Bean("mappingMongoConverter") //使用自定义的typeMapper去除写入mongodb时的“_class”字段
    public MappingMongoConverter mappingMongoConverter(@Qualifier("mongoDbFactory") MongoDbFactory mongoDbFactory,
                                                       @Qualifier("mongoMappingContext") MongoMappingContext mongoMappingContext) throws Exception {
        DefaultDbRefResolver dbRefResolver = new DefaultDbRefResolver(mongoDbFactory);
        MappingMongoConverter converter = new MappingMongoConverter(dbRefResolver, mongoMappingContext);
        converter.setTypeMapper(new DefaultMongoTypeMapper(null));
        return converter;
    }

    @Primary
    @Bean(name = "mongoTemplate")
    public MongoTemplate getMongoTemplate(@Qualifier("mongoDbFactory") MongoDbFactory mongoDbFactory,
                                          @Qualifier("mappingMongoConverter") MappingMongoConverter mappingMongoConverter) throws Exception {
        return new MongoTemplate(mongoDbFactory, mappingMongoConverter);
    }
}
```

第二数据源

```java
package com.winterchen.label.service.configuration;

import com.mongodb.MongoClient;
import com.mongodb.MongoClientURI;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.MongoDbFactory;
import org.springframework.data.mongodb.MongoTransactionManager;
import org.springframework.data.mongodb.config.AbstractMongoConfiguration;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.SimpleMongoDbFactory;
import org.springframework.data.mongodb.core.convert.DefaultDbRefResolver;
import org.springframework.data.mongodb.core.convert.DefaultMongoTypeMapper;
import org.springframework.data.mongodb.core.convert.MappingMongoConverter;
import org.springframework.data.mongodb.core.mapping.MongoMappingContext;

/**
 * @author winterchen
 * @version 1.0
 * @date 2020/12/2 3:53 下午
 * @description TODO
 **/
@Configuration
public class TargetMongoConfig extends AbstractMongoConfiguration {

    @Value("${spring.data.mongodb-target.uri}")
    private String uri;

    @Value("${spring.data.mongodb-target.database}")
    private String database;

    @Override
    protected String getDatabaseName() {
        return database;
    }

    @Override
    public MongoClient mongoClient() {
        MongoClientURI mongoClientURI = new MongoClientURI(uri);
        return new MongoClient(mongoClientURI);
    }

    @Bean("targetMongoMappingContext")
    public MongoMappingContext mongoMappingContext() {
        MongoMappingContext mappingContext = new MongoMappingContext();
        return mappingContext;
    }

    @Bean("TARGET_MONGO_TRANSACTION_MANAGER")
    public MongoTransactionManager transactionManager(@Qualifier("targetMongoDbFactory") MongoDbFactory mongoDbFactory) throws Exception {
        return new MongoTransactionManager(mongoDbFactory);
    }

    @Bean("targetMongoDbFactory")
    public MongoDbFactory mongoDbFactory() {
        return new SimpleMongoDbFactory(mongoClient(), getDatabaseName());
    }

    @Bean("targetMappingMongoConverter") //使用自定义的typeMapper去除写入mongodb时的“_class”字段
    public MappingMongoConverter mappingMongoConverter(@Qualifier("targetMongoDbFactory") MongoDbFactory mongoDbFactory,
                                                       @Qualifier("targetMongoMappingContext") MongoMappingContext mongoMappingContext) throws Exception {
        DefaultDbRefResolver dbRefResolver = new DefaultDbRefResolver(mongoDbFactory);
        MappingMongoConverter converter = new MappingMongoConverter(dbRefResolver, mongoMappingContext);
        converter.setTypeMapper(new DefaultMongoTypeMapper(null));
        return converter;
    }

    /**
     * MongoTemplate实现
     */
    @Bean(name = "targetMongoTemplate")
    public MongoTemplate getMongoTemplate(@Qualifier("targetMongoDbFactory") MongoDbFactory mongoDbFactory,
                                          @Qualifier("mappingMongoConverter") MappingMongoConverter mappingMongoConverter) throws Exception {
        return new MongoTemplate(mongoDbFactory, mappingMongoConverter);
    }

}
```

## 使用

默认的使用：

```java
		@Autowired
    private MongoTemplate mongoTemplate;

```

使用另一个数据源，只需要指定名称即可:

```java
		@Autowired
    @Qualifier("targetMongoTemplate")
    private MongoTemplate targetMongoTemplate;
```

## 事务

普通的：

```java
@Transactional(rollbackFor = Throwable.class)
```

其他数据源指定事务管理器即可

```java
@Transactional(rollbackFor = Throwable.class, transactionManager = "TARGET_MONGO_TRANSACTION_MANAGER")
```

注意：两种事务不能混合使用