---
layout: post
title: springboot2.0 mybatis 使用多数据源
date:  2018-05-30 18:39
comments: true
tags: [Spring Boot, mybatis]
brief: "Spring boot 入门"
reward: true
categories: Spring Boot
keywords: springboot,mybatis,java
cover: https://images.unsplash.com/photo-1496737018672-b1a6be2e949c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=f0aa3d84be0ad9a656a27a318f055ee9&auto=format&fit=crop&w=2691&q=80
image: https://images.unsplash.com/photo-1496737018672-b1a6be2e949c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=f0aa3d84be0ad9a656a27a318f055ee9&auto=format&fit=crop&w=2691&q=80
---


![多数据源](http://img.winterchen.com/multi-database.png)
springboot2.0正式版发布之后，很多的组件集成需要变更了，这次将多数据源的使用踩的坑给大家填一填。当前多数据源的主要为主从库，读写分离，动态切换数据源。使用的技术就是AOP进行dao方法的切面，所以大家的方法名开头都需要按照规范进行编写，如：`get***`、`add***` 等等，
<!-- more -->
## 起步基础

本次的教程需要有springboot2.0集成mybatis 作为基础：

* 博客地址：[springboot2.0 Mybatis 整合 (springboot2.0版本)](https://blog.csdn.net/Winter_chen001/article/details/80010967)

* 基础项目源码：[https://github.com/WinterChenS/springboot2-mybatis-demo](https://github.com/WinterChenS/springboot2-mybatis-demo)

需要以上的步骤作为基础，运行成功之后可就可以开始配置多数据源了

## 开始动手

### 添加依赖

```
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-aop</artifactId>
</dependency>
```

### 修改启动类

修改之前：

```java
@SpringBootApplication
@MapperScan("com.winterchen.dao")
public class SpringBootMybatisMutilDatabaseApplication {

    public static void main(String[] args) {
        SpringApplication.run(SpringBootMybatisMutilDatabaseApplication.class, args);
    }
}
```

修改之后：

```java
@SpringBootApplication
public class SpringBootMybatisMutilDatabaseApplication {

    public static void main(String[] args) {
        SpringApplication.run(SpringBootMybatisMutilDatabaseApplication.class, args);
    }
}
```

因为改用多数据源，所以dao接口的扫描我们放在配置类中进行

### 修改项目配置

首先我们需要在配置文件中配置多数据源，看一下原本项目的配置：

```yaml
spring:
    datasource:
        name: mysql_test
        #-----------------start-----------------#  （1）
        type: com.alibaba.druid.pool.DruidDataSource
        #-----------------end-----------------#
        #druid相关配置
        druid:
          #监控统计拦截的filters
          filters: stat
          #-----------------start-----------------# （2）
          driver-class-name: com.mysql.jdbc.Driver
          #基本属性
          url: jdbc:mysql://127.0.0.1:3306/mytest?useUnicode=true&characterEncoding=UTF-8&allowMultiQueries=true
          username: root
          password: root
           #-----------------end-----------------#
          #配置初始化大小/最小/最大
          initial-size: 1
          min-idle: 1
          max-active: 20
          #获取连接等待超时时间
          max-wait: 60000
          #间隔多久进行一次检测，检测需要关闭的空闲连接
          time-between-eviction-runs-millis: 60000
          #一个连接在池中最小生存的时间
          min-evictable-idle-time-millis: 300000
          validation-query: SELECT 'x'
          test-while-idle: true
          test-on-borrow: false
          test-on-return: false
          #打开PSCache，并指定每个连接上PSCache的大小。oracle设为true，mysql设为false。分库分表较多推荐设置为false
          pool-prepared-statements: false
          max-pool-prepared-statement-per-connection-size: 20
```

**需要修改的地方: **

* (1) 需要将 `type: com.alibaba.druid.pool.DruidDataSource`去除；

* (2) 将关于数据库的连接信息: `driver-class-name`、`url`、`username` 、`password`  去除；

**修改后：**

```yaml
spring:
    datasource:
        name: mysql_test
        #-------------- start ----------------# (1)
        master:
          #基本属性--注意，这里的为【jdbcurl】-- 默认使用HikariPool作为数据库连接池
          jdbcurl: jdbc:mysql://127.0.0.1:3306/mytest?useUnicode=true&characterEncoding=UTF-8&allowMultiQueries=true
          username: root
          password: root
          driver-class-name: com.mysql.jdbc.Driver
        slave:
          #基本属性--注意，这里为 【url】-- 使用 druid 作为数据库连接池
          url: jdbc:mysql://127.0.0.1:3306/mytest?useUnicode=true&characterEncoding=UTF-8&allowMultiQueries=true
          username: root
          password: root
          driver-class-name: com.mysql.jdbc.Driver
        read: get,select,count,list,query,find
        write: add,create,update,delete,remove,insert
        #-------------- end ----------------#
        #druid相关配置
        druid:
          #监控统计拦截的filters
          filters: stat,wall
          #配置初始化大小/最小/最大
          initial-size: 1
          min-idle: 1
          max-active: 20
          #获取连接等待超时时间
          max-wait: 60000
          #间隔多久进行一次检测，检测需要关闭的空闲连接
          time-between-eviction-runs-millis: 60000
          #一个连接在池中最小生存的时间
          min-evictable-idle-time-millis: 300000
          validation-query: SELECT 'x'
          test-while-idle: true
          test-on-borrow: false
          test-on-return: false
          #打开PSCache，并指定每个连接上PSCache的大小。oracle设为true，mysql设为false。分库分表较多推荐设置为false
          pool-prepared-statements: false
          max-pool-prepared-statement-per-connection-size: 20
```

需要修改地方：

* (1) 在如上的配置中添加`master`、`slave`两个数据源;

**注意！！**两中数据源中有一处是不一样的，原因是因为`master`数据源使用 `Hikari`连接池，`slave`使用的是`druid`作为数据库连接池，所以两处的配置分别为：

```yaml
master:
    jdbcurl: jdbc:mysql://127.0.0.1:3306/mytest?useUnicode=true&characterEncoding=UTF-8&allowMultiQueries=true
```

```yaml
slave:
    url: jdbc:mysql://127.0.0.1:3306/mytest?useUnicode=true&characterEncoding=UTF-8&allowMultiQueries=true
```

数据库的连接不一样的，如果配置成一样的会在启动的时候报错。

**注意！！**

dao接口方法的方法名规则配置在这里了，当然可以自行更改：

```yaml
read: get,select,count,list,query,find
write: add,create,update,delete,remove,insert
```

### 创建配置包

首先在项目的`/src/main/java/com/winterchen/`包下创建`config`包

![创建config包](http://img.winterchen.com/WX20180530-163257@2x.png)

### 创建数据源类型的枚举DatabaseType

该枚举类主要用来区分读写

```java
package com.winterchen.config;

/**
 * 列出数据源类型
 * Created by Donghua.Chen on 2018/5/29.
 */
public enum DatabaseType {

    master("write"), slave("read");


    DatabaseType(String name) {
        this.name = name;
    }

    private String name;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    @Override
    public String toString() {
        return "DatabaseType{" +
                "name='" + name + '\'' +
                '}';
    }
}
```

### 创建线程安全的DatabaseType容器

多数据源必须要保证数据源的线程安全的

```java
package com.winterchen.config;

/**
 * 保存一个线程安全的DatabaseType容器
 * Created by Donghua.Chen on 2018/5/29.
 */
public class DatabaseContextHolder {

        //用于存放多线程环境下的成员变量
    private static final ThreadLocal<DatabaseType> contextHolder = new ThreadLocal<>();

    public static void setDatabaseType(DatabaseType type) {
        contextHolder.set(type);
    }

    public static DatabaseType getDatabaseType() {
        return contextHolder.get();
    }
}
```

### 创建动态数据源

实现数据源切换的功能就是自定义一个类扩展AbstractRoutingDataSource抽象类，其实该相当于数据源DataSource的路由中介，可以实现在项目运行时根据相应key值切换到对应的数据源DataSource上，有兴趣的同学可以看看它的源码。

```java
public class DynamicDataSource extends AbstractRoutingDataSource {

    static final Map<DatabaseType, List<String>> METHOD_TYPE_MAP = new HashMap<>();


    @Nullable
    @Override
    protected Object determineCurrentLookupKey() {
        DatabaseType type = DatabaseContextHolder.getDatabaseType();
        logger.info("====================dataSource ==========" + type);
        return type;
    }

    void setMethodType(DatabaseType type, String content) {
        List<String> list = Arrays.asList(content.split(","));
        METHOD_TYPE_MAP.put(type, list);
    }

}
```

### 创建数据源配置类DataSourceConfig

```java
@Configuration
@MapperScan("com.winterchen.dao")
@EnableTransactionManagement
public class DataSourceConfig {

    private static Logger logger = LoggerFactory.getLogger(DataSourceConfig.class);

    @Autowired
    private Environment env;  // (1)

    @Autowired
    private DataSourceProperties properties;  // (2)

    @Value("${spring.datasource.druid.filters}")   // (3)
    private String filters;

    @Value("${spring.datasource.druid.initial-size}")
    private Integer initialSize;

    @Value("${spring.datasource.druid.min-idle}")
    private Integer minIdle;

    @Value("${spring.datasource.druid.max-active}")
    private Integer maxActive;

    @Value("${spring.datasource.druid.max-wait}")
    private Integer maxWait;

    @Value("${spring.datasource.druid.time-between-eviction-runs-millis}")
    private Long timeBetweenEvictionRunsMillis;

    @Value("${spring.datasource.druid.min-evictable-idle-time-millis}")
    private Long minEvictableIdleTimeMillis;

    @Value("${spring.datasource.druid.validation-query}")
    private String validationQuery;

    @Value("${spring.datasource.druid.test-while-idle}")
    private Boolean testWhileIdle;

    @Value("${spring.datasource.druid.test-on-borrow}")
    private boolean testOnBorrow;

    @Value("${spring.datasource.druid.test-on-return}")
    private boolean testOnReturn;

    @Value("${spring.datasource.druid.pool-prepared-statements}")
    private boolean poolPreparedStatements;

    @Value("${spring.datasource.druid.max-pool-prepared-statement-per-connection-size}")
    private Integer maxPoolPreparedStatementPerConnectionSize;

    /**
     * 通过Spring JDBC 快速创建 DataSource
     * @return
     */
    @Bean(name = "masterDataSource")
    @Qualifier("masterDataSource")
    @ConfigurationProperties(prefix = "spring.datasource.master")  // (4)
    public DataSource masterDataSource() {
        return DataSourceBuilder.create().build();
    }


    /**
     * 手动创建DruidDataSource,通过DataSourceProperties 读取配置
     * @return
     * @throws SQLException
     */
    @Bean(name = "slaveDataSource")
    @Qualifier("slaveDataSource")
    @ConfigurationProperties(prefix = "spring.datasource.slave")
    public DataSource slaveDataSource() throws SQLException {
        DruidDataSource dataSource = new DruidDataSource();
        dataSource.setFilters(filters);
        dataSource.setUrl(properties.getUrl());
        dataSource.setDriverClassName(properties.getDriverClassName());
        dataSource.setUsername(properties.getUsername());
        dataSource.setPassword(properties.getPassword());
        dataSource.setInitialSize(initialSize);
        dataSource.setMinIdle(minIdle);
        dataSource.setMaxActive(maxActive);
        dataSource.setMaxWait(maxWait);
        dataSource.setTimeBetweenEvictionRunsMillis(timeBetweenEvictionRunsMillis);
        dataSource.setMinEvictableIdleTimeMillis(minEvictableIdleTimeMillis);
        dataSource.setValidationQuery(validationQuery);
        dataSource.setTestWhileIdle(testWhileIdle);
        dataSource.setTestOnBorrow(testOnBorrow);
        dataSource.setTestOnReturn(testOnReturn);
        dataSource.setPoolPreparedStatements(poolPreparedStatements);
        dataSource.setMaxPoolPreparedStatementPerConnectionSize(maxPoolPreparedStatementPerConnectionSize);
        return dataSource;
    }


    /**
     *  构造多数据源连接池
     *  Master 数据源连接池采用 HikariDataSource
     *  Slave  数据源连接池采用 DruidDataSource
     * @param master
     * @param slave
     * @return
     */
    @Bean
    @Primary
    public DynamicDataSource dataSource(@Qualifier("masterDataSource") DataSource master,
                                        @Qualifier("slaveDataSource") DataSource slave) {
        Map<Object, Object> targetDataSources = new HashMap<>();
        targetDataSources.put(DatabaseType.master, master);
        targetDataSources.put(DatabaseType.slave, slave);

        DynamicDataSource dataSource = new DynamicDataSource();
        dataSource.setTargetDataSources(targetDataSources);// 该方法是AbstractRoutingDataSource的方法
        dataSource.setDefaultTargetDataSource(slave);// 默认的datasource设置为myTestDbDataSource

        String read = env.getProperty("spring.datasource.read");
        dataSource.setMethodType(DatabaseType.slave, read);

        String write = env.getProperty("spring.datasource.write");
        dataSource.setMethodType(DatabaseType.master, write);

        return dataSource;
    }

    @Bean
    public SqlSessionFactory sqlSessionFactory(@Qualifier("masterDataSource") DataSource myTestDbDataSource,
                                               @Qualifier("slaveDataSource") DataSource myTestDb2DataSource) throws Exception {
        SqlSessionFactoryBean fb = new SqlSessionFactoryBean();
        fb.setDataSource(this.dataSource(myTestDbDataSource, myTestDb2DataSource));
        fb.setTypeAliasesPackage(env.getProperty("mybatis.type-aliases-package"));
        fb.setMapperLocations(new PathMatchingResourcePatternResolver().getResources(env.getProperty("mybatis.mapper-locations")));
        return fb.getObject();
    }


    @Bean
    public DataSourceTransactionManager transactionManager(DynamicDataSource dataSource) throws Exception {
        return new DataSourceTransactionManager(dataSource);
    }
}
```

以上的代码中：

* (1)  注入类 `Environment` 可以很方便的获取配置文件中的参数

* (2)  `DataSourceProperties`和（4）中的 `@ConfigurationProperties(prefix = "spring.datasource.master")`配合使用，将配置文件中的配置数据自动封装到实体类`DataSourceProperties`中

* (3) `@Value`注解同样是指定获取配置文件中的配置;

更详细的配置大家可以参考官方文档。

### 配置AOP

本章的开头已经说过，多数据源动态切换的原理是利用AOP切面进行动态的切换的，当调用`dao`接口方法时，根据接口方法的方法名开头进行区分读写。

```java
/**
 *
 * 动态处理数据源，根据命名区分
 * Created by Donghua.Chen on 2018/5/29.
 */
@Aspect
@Component
@EnableAspectJAutoProxy(proxyTargetClass = true)
public class DataSourceAspect {


    private static Logger logger = LoggerFactory.getLogger(DataSourceAspect.class);

    @Pointcut("execution(* com.winterchen.dao.*.*(..))")//切点
    public void aspect() {

    }


    @Before("aspect()")
    public void before(JoinPoint point) { //在指定切点的方法之前执行
        String className = point.getTarget().getClass().getName();
        String method = point.getSignature().getName();
        String args = StringUtils.join(point.getArgs(), ",");
        logger.info("className:{}, method:{}, args:{} ", className, method, args);
        try {
            for (DatabaseType type : DatabaseType.values()) {
                List<String> values = DynamicDataSource.METHOD_TYPE_MAP.get(type);
                for (String key : values) {
                    if (method.startsWith(key)) {
                        logger.info(">>{} 方法使用的数据源为:{}<<", method, key);
                        DatabaseContextHolder.setDatabaseType(type);
                        DatabaseType types = DatabaseContextHolder.getDatabaseType();
                        logger.info(">>{}方法使用的数据源为:{}<<", method, types);
                    }
                }
            }
        } catch (Exception e) {
            logger.error(e.getMessage(), e);
        }
    }
}
```

如上可以看到，切点切在`dao`的接口方法中，根据接口方法的方法名进行匹配数据源，然后将数据源set到用于存放数据源线程安全的容器中；

完整的项目结构了解一下：

![完整项目结构](http://img.winterchen.com/WX20180530-172445@2x.png)

## 项目启动

启动成功：

```
2018-05-30 17:27:16.492  INFO 35406 --- [           main] o.s.j.e.a.AnnotationMBeanExporter        : Located MBean 'masterDataSource': registering with JMX server as MBean [com.zaxxer.hikari:name=masterDataSource,type=HikariDataSource]
2018-05-30 17:27:16.496  INFO 35406 --- [           main] o.s.j.e.a.AnnotationMBeanExporter        : Located MBean 'slaveDataSource': registering with JMX server as MBean [com.alibaba.druid.pool:name=slaveDataSource,type=DruidDataSource]
2018-05-30 17:27:16.498  INFO 35406 --- [           main] o.s.j.e.a.AnnotationMBeanExporter        : Located MBean 'statFilter': registering with JMX server as MBean [com.alibaba.druid.filter.stat:name=statFilter,type=StatFilter]
2018-05-30 17:27:16.590  INFO 35406 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 8080 (http) with context path ''
2018-05-30 17:27:16.598  INFO 35406 --- [           main] pringBootMybatisMutilDatabaseApplication : Started SpringBootMybatisMutilDatabaseApplication in 11.523 seconds (JVM running for 13.406)
```

添加用户（write）：

![添加用户](http://img.winterchen.com/WX20180530-172930@2x.png)

日志：

```
2018-05-30 17:29:07.347  INFO 35406 --- [nio-8080-exec-1] com.winterchen.config.DataSourceAspect   : className:com.sun.proxy.$Proxy73, method:insert, args:com.winterchen.model.UserDomain@4b5b52dc
2018-05-30 17:29:07.350  INFO 35406 --- [nio-8080-exec-1] com.winterchen.config.DataSourceAspect   : >>insert 方法使用的数据源为:insert<<
2018-05-30 17:29:07.351  INFO 35406 --- [nio-8080-exec-1] com.winterchen.config.DataSourceAspect   : >>insert方法使用的数据源为:DatabaseType{name='write'}<<
2018-05-30 17:29:07.461  INFO 35406 --- [nio-8080-exec-1] com.winterchen.config.DynamicDataSource  : ====================dataSource ==========DatabaseType{name='write'}
2018-05-30 17:29:07.462  INFO 35406 --- [nio-8080-exec-1] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Starting...
2018-05-30 17:29:07.952  INFO 35406 --- [nio-8080-exec-1] com.zaxxer.hikari.HikariDataSource       : HikariPool-1 - Start completed.
```

可以看出使用的就是`write`数据源，并且该数据源是使用`HikariPool`作为数据库连接池的

查询用户（read）：

![查询用户](http://img.winterchen.com/WX20180530-172958@2x.png)

日志：

```
2018-05-30 17:29:41.616  INFO 35406 --- [nio-8080-exec-2] com.winterchen.config.DataSourceAspect   : className:com.sun.proxy.$Proxy73, method:selectUsers, args:
2018-05-30 17:29:41.618  INFO 35406 --- [nio-8080-exec-2] com.winterchen.config.DataSourceAspect   : >>selectUsers 方法使用的数据源为:select<<
2018-05-30 17:29:41.618  INFO 35406 --- [nio-8080-exec-2] com.winterchen.config.DataSourceAspect   : >>selectUsers方法使用的数据源为:DatabaseType{name='read'}<<
2018-05-30 17:29:41.693  INFO 35406 --- [nio-8080-exec-2] com.winterchen.config.DynamicDataSource  : ====================dataSource ==========DatabaseType{name='read'}
2018-05-30 17:29:41.982  INFO 35406 --- [nio-8080-exec-2] com.alibaba.druid.pool.DruidDataSource   : {dataSource-1} inited
```

可以看出使用的是`read`数据源。

源码地址：[戳这里](https://github.com/WinterChenS/springboot-learning-experience/tree/master/spring-boot-mybatis-mutil-database)






springboot技术交流群：681513531