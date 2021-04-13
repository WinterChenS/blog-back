---
layout: post
title: springboot集成hive实战
date: 2020-12-01 19:30
comments: true
tags: [hadoop, hive, springboot]
brief: [share]
reward: true
categories: hadoop
keywords: hadoop, hive, springboot
cover: https://gitee.com/winter_chen/img/raw/master/blog/20210413115354.jpeg
image: https://gitee.com/winter_chen/img/raw/master/blog/20210413115354.jpeg
---

springboot集成hive实现基本的api调用

## maven坐标

```xml
				<!-- hadoop -->
				<dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-common</artifactId>
            <version>${hadoop.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-streaming</artifactId>
            <version>${hadoop.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-yarn-common</artifactId>
            <version>${hadoop.version}</version>
            <exclusions>
                <exclusion>
                    <groupId>com.google.guava</groupId>
                    <artifactId>guava</artifactId>
                </exclusion>
            </exclusions>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-distcp</artifactId>
            <version>${hadoop.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-mapreduce-client-core</artifactId>
            <version>${hadoop.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-hdfs</artifactId>
            <version>${hadoop.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-mapreduce-client-jobclient</artifactId>
            <version>${hadoop.version}</version>
            <scope>provided</scope>
        </dependency>

        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>druid</artifactId>
            <version>1.2.1</version>
        </dependency>

        <!-- hive依赖 -->
        <dependency>
            <groupId>org.apache.hive</groupId>
            <artifactId>hive-jdbc</artifactId>
            <version>2.3.0</version>
        </dependency>

        <!-- 中文分词器 -->
        <dependency>
            <groupId>cn.bestwu</groupId>
            <artifactId>ik-analyzers</artifactId>
            <version>5.1.0</version>
        </dependency>
```

## 配置：

```yaml
spring:
  application:
    name: hadoop-demo
  datasource:
    hive: #hive数据源
      url: jdbc:hive2://192.168.150.119:10000/default
      type: com.alibaba.druid.pool.DruidDataSource
      username: winterchen
      password: winterchen
      driver-class-name: org.apache.hive.jdbc.HiveDriver
    common-config: #连接池统一配置，应用到所有的数据源
      initialSize: 1
      minIdle: 1
      maxIdle: 5
      maxActive: 50
      maxWait: 10000
      timeBetweenEvictionRunsMillis: 10000
      minEvictableIdleTimeMillis: 300000
      validationQuery: select 'x'
      testWhileIdle: true
      testOnBorrow: false
      testOnReturn: false
      poolPreparedStatements: true
      maxOpenPreparedStatements: 20
      filters: stat
```

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
@Component
@ConfigurationProperties(prefix = "spring.datasource.hive", ignoreUnknownFields = false)
public class HiveJdbcProperties {

    private String url;

    private String type;

    private String username;

    private String password;

    private String driverClassName;

}
```

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
@Component
@ConfigurationProperties(prefix = "spring.datasource.common-config", ignoreUnknownFields = false)
public class DataSourceCommonProperties {

    private int initialSize = 10;
    private int minIdle;
    private int maxIdle;
    private int maxActive;
    private int maxWait;
    private int timeBetweenEvictionRunsMillis;
    private int minEvictableIdleTimeMillis;
    private String validationQuery;
    private boolean testWhileIdle;
    private boolean testOnBorrow;
    private boolean testOnReturn;
    private boolean poolPreparedStatements;
    private int maxOpenPreparedStatements;
    private String filters;

    private String mapperLocations;
    private String typeAliasPackage;
}
```

```java
@Slf4j
@Configuration
@EnableConfigurationProperties({HiveJdbcProperties.class, DataSourceCommonProperties.class})
public class HiveDruidConfiguration {

    @Autowired
    private HiveJdbcProperties hiveJdbcProperties;

    @Autowired
    private DataSourceCommonProperties dataSourceCommonProperties;

    @Bean("hiveDruidDataSource") //新建bean实例
    @Qualifier("hiveDruidDataSource")//标识
    public DataSource dataSource(){
        DruidDataSource datasource = new DruidDataSource();

        //配置数据源属性
        datasource.setUrl(hiveJdbcProperties.getUrl());
        datasource.setUsername(hiveJdbcProperties.getUsername());
        datasource.setPassword(hiveJdbcProperties.getPassword());
        datasource.setDriverClassName(hiveJdbcProperties.getDriverClassName());

        //配置统一属性
        datasource.setInitialSize(dataSourceCommonProperties.getInitialSize());
        datasource.setMinIdle(dataSourceCommonProperties.getMinIdle());
        datasource.setMaxActive(dataSourceCommonProperties.getMaxActive());
        datasource.setMaxWait(dataSourceCommonProperties.getMaxWait());
        datasource.setTimeBetweenEvictionRunsMillis(dataSourceCommonProperties.getTimeBetweenEvictionRunsMillis());
        datasource.setMinEvictableIdleTimeMillis(dataSourceCommonProperties.getMinEvictableIdleTimeMillis());
        datasource.setValidationQuery(dataSourceCommonProperties.getValidationQuery());
        datasource.setTestWhileIdle(dataSourceCommonProperties.isTestWhileIdle());
        datasource.setTestOnBorrow(dataSourceCommonProperties.isTestOnBorrow());
        datasource.setTestOnReturn(dataSourceCommonProperties.isTestOnReturn());
        datasource.setPoolPreparedStatements(dataSourceCommonProperties.isPoolPreparedStatements());
        try {
            datasource.setFilters(dataSourceCommonProperties.getFilters());
        } catch (SQLException e) {
            log.error("Druid configuration initialization filter error.", e);
        }
        return datasource;
    }
}
```

注册jdbcTemplate 

```java
@Configuration
public class HiveJdbcConfiguration {

    @Bean("hiveJdbcTemplate")
    @Qualifier("hiveJdbcTemplate")
    public JdbcTemplate jdbcTemplate(@Qualifier("hiveDruidDataSource") DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }

}
```

## 基本api调用

```java
package com.winterchen.hadoopdemo.service;

import java.util.List;

public interface HiveService {

    Object select(String hql);

    List<String> listAllTables();

    List<String> describeTable(String tableName);

    List<String> selectFromTable(String tableName);

}
```

```java
package com.winterchen.hadoopdemo.service.impl;

import com.winterchen.hadoopdemo.service.HiveService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import javax.sql.DataSource;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Slf4j
@Service
public class HiveServiceImpl implements HiveService {

    @Autowired
    @Qualifier("hiveJdbcTemplate")
    private JdbcTemplate hiveJdbcTemplate;

    @Autowired
    @Qualifier("hiveDruidDataSource")
    private DataSource hiveDruidDataSource;

    @Override
    public Object select(String hql) {
        return hiveJdbcTemplate.queryForObject(hql, Object.class);
    }

    @Override
    public List<String> listAllTables() {
        List<String> result = new ArrayList<>();
        try {
            Statement statement = hiveDruidDataSource.getConnection().createStatement();
            String sql = "show tables";
            log.info("Running: " + sql);
            ResultSet resultSet = statement.executeQuery(sql);
            while (resultSet.next()) {
                result.add(resultSet.getString(1));
            }
            return result;
        } catch (SQLException throwables) {
            log.error(throwables.getMessage());
        }

        return Collections.emptyList();
    }

    @Override
    public List<String> describeTable(String tableName) {
        if (StringUtils.isEmpty(tableName)){
            return Collections.emptyList();
        }
        List<String> result = new ArrayList<>();
        try {
            Statement statement = hiveDruidDataSource.getConnection().createStatement();
            String sql = "describe " + tableName;
            log.info("Running" + sql);
            ResultSet resultSet = statement.executeQuery(sql);
            while (resultSet.next()) {
                result.add(resultSet.getString(1));
            }
            return result;
        } catch (SQLException throwables) {
            log.error(throwables.getMessage());
        }
        return Collections.emptyList();
    }

    @Override
    public List<String> selectFromTable(String tableName) {
        if (StringUtils.isEmpty(tableName)){
            return Collections.emptyList();
        }
        List<String> result = new ArrayList<>();
        try {
            Statement statement = hiveDruidDataSource.getConnection().createStatement();
            String sql = "select * from " + tableName;
            log.info("Running" + sql);
            ResultSet resultSet = statement.executeQuery(sql);
            int columnCount = resultSet.getMetaData().getColumnCount();
            String str = null;
            while (resultSet.next()) {
                str = "";
                for (int i = 1; i < columnCount; i++) {
                    str += resultSet.getString(i) + " ";
                }
                str += resultSet.getString(columnCount);
                log.info(str);
                result.add(str);
            }
            return result;
        } catch (SQLException throwables) {
            log.error(throwables.getMessage());
        }
        return Collections.emptyList();
    }
}
```

hive本身就是基于hadoop的MapReduce的一层封装，所以对于hive的操作都是查询和新增等操作，其他的api请参考jdbctemplate接口

源码地址: 

[WinterChenS/springboot-learning-experience](https://github.com/WinterChenS/springboot-learning-experience/tree/master/spring-boot-hadoop)