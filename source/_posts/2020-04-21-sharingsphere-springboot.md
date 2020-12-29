---
layout: post
title: springboot 整合 Shardingsphere 4.0 分库分表
date: 2020-04-21 13:50
comments: true
tags: [sharingsphere,springboot,mybatis-plus]
brief: [sharingsphere]
reward: true
categories: sharingsphere
keywords: sharingsphere,springboot,mybatis-plus
cover: http://img.winterchen.com/20200613204014.png
image: http://img.winterchen.com/20200613204014.png
---

  > 最近Shardingsphere在Apache Software Foundation 简称ASF 毕业成为Apache顶级项目，也是目前ASF收个分布式数据库中间件项目，未来可期啊，今天我们就搭建一下springboot整合Shardingsphere4.0版本。
  
  
##  依赖：
-   jdk1.8
-   maven3.6.3
-   mybatis plus
-   mysql8.0
-   Shardingsphere 4.0


## 数据库的结构：

--|
  |- ds0
  |   |- t_order0
  |   |- t_order1
  |
  |- ds1
      |- t_order0
      |- t_order1
      
      
### 创建数据库

#### 数据库ds0
```sql
CREATE DATABASE IF NOT EXISTS `ds0` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;
USE `ds0`;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for t_order0
-- ----------------------------
DROP TABLE IF EXISTS `t_order0`;
CREATE TABLE `t_order0`  (
  `order_id` bigint(0) NOT NULL COMMENT '订单号（主键）',
  `order_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '订单名称',
  `order_status` int(0) NULL DEFAULT NULL COMMENT '订单状态',
  `user_id` bigint(0) NOT NULL COMMENT '用户id',
  PRIMARY KEY (`order_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for t_order1
-- ----------------------------
DROP TABLE IF EXISTS `t_order1`;
CREATE TABLE `t_order1`  (
  `order_id` bigint(0) NOT NULL COMMENT '订单号（主键）',
  `order_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '订单名称',
  `order_status` int(0) NULL DEFAULT NULL COMMENT '订单状态',
  `user_id` bigint(0) NOT NULL COMMENT '用户id',
  PRIMARY KEY (`order_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

SET FOREIGN_KEY_CHECKS = 1;
```

#### 数据库ds1

```sql
CREATE DATABASE IF NOT EXISTS `ds1` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;
USE `ds1`;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for t_order0
-- ----------------------------
DROP TABLE IF EXISTS `t_order0`;
CREATE TABLE `t_order0`  (
  `order_id` bigint(0) NOT NULL COMMENT '订单号（主键）',
  `order_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '订单名称',
  `order_status` int(0) NULL DEFAULT NULL COMMENT '订单状态',
  `user_id` bigint(0) NOT NULL COMMENT '用户id',
  PRIMARY KEY (`order_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for t_order1
-- ----------------------------
DROP TABLE IF EXISTS `t_order1`;
CREATE TABLE `t_order1`  (
  `order_id` bigint(0) NOT NULL COMMENT '订单号（主键）',
  `order_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '订单名称',
  `order_status` int(0) NULL DEFAULT NULL COMMENT '订单状态',
  `user_id` bigint(0) NOT NULL COMMENT '用户id',
  PRIMARY KEY (`order_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

SET FOREIGN_KEY_CHECKS = 1;
```

## pom.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.2.6.RELEASE</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>
    <groupId>com.winterchen</groupId>
    <artifactId>shardingsphere-demo</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>shardingsphere-demo</name>
    <description>shardingsphere demo</description>

    <properties>
        <java.version>1.8</java.version>
        <sharding-sphere.version>4.0.1</sharding-sphere.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <!--mysql，根据自己数据库版本进行相关调整，不然会报错-->
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>8.0.13</version>
            <scope>runtime</scope>
        </dependency>
        <!--Mybatis-Plus-->
        <dependency>
            <groupId>com.baomidou</groupId>
            <artifactId>mybatis-plus-boot-starter</artifactId>
            <version>3.1.1</version>
        </dependency>
        <!-- for spring boot -->
        <dependency>
            <groupId>org.apache.shardingsphere</groupId>
            <artifactId>sharding-jdbc-spring-boot-starter</artifactId>
            <version>${sharding-sphere.version}</version>
        </dependency>

        <!-- for spring namespace -->
        <dependency>
            <groupId>org.apache.shardingsphere</groupId>
            <artifactId>sharding-jdbc-spring-namespace</artifactId>
            <version>${sharding-sphere.version}</version>
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
> 注意：数据库驱动版本，请根据自己数据库版本进行相关调整，不然会报错

## 项目配置

### application.properties

```properties
server.port=8098

# 数据源 ds0,ds1
spring.shardingsphere.datasource.names=ds0,ds1
# 第一个数据库
spring.shardingsphere.datasource.ds0.type=com.zaxxer.hikari.HikariDataSource
spring.shardingsphere.datasource.ds0.driver-class-name=com.mysql.cj.jdbc.Driver
spring.shardingsphere.datasource.ds0.jdbc-url=jdbc:mysql://192.168.133.134:3306/ds0?serverTimezone=UTC&useUnicode=true&characterEncoding=utf8&characterSetResults=utf8&useSSL=false&verifyServerCertificate=false&autoReconnct=true&autoReconnectForPools=true&allowMultiQueries=true
spring.shardingsphere.datasource.ds0.username=root
spring.shardingsphere.datasource.ds0.password=root

# 第二个数据库
spring.shardingsphere.datasource.ds1.type=com.zaxxer.hikari.HikariDataSource
spring.shardingsphere.datasource.ds1.driver-class-name=com.mysql.cj.jdbc.Driver
spring.shardingsphere.datasource.ds1.jdbc-url=jdbc:mysql://192.168.133.134:3306/ds1?serverTimezone=UTC&useUnicode=true&characterEncoding=utf8&characterSetResults=utf8&useSSL=false&verifyServerCertificate=false&autoReconnct=true&autoReconnectForPools=true&allowMultiQueries=true
spring.shardingsphere.datasource.ds1.username=root
spring.shardingsphere.datasource.ds1.password=root

# 水平拆分的数据库（表） 配置分库 + 分表策略 行表达式分片策略
# 分库策略
spring.shardingsphere.sharding.default-database-strategy.inline.sharding-column=user_id
spring.shardingsphere.sharding.default-database-strategy.inline.algorithm-expression=ds$->{user_id % 2}


# 分表策略 其中t_order为逻辑表 分表主要取决于order_id行
spring.shardingsphere.sharding.tables.t_order.actual-data-nodes=ds$->{0..1}.t_order$->{0..1}
spring.shardingsphere.sharding.tables.t_order.table-strategy.inline.sharding-column=order_id
spring.shardingsphere.sharding.tables.t_order.key-generator.column=order_id
spring.shardingsphere.sharding.tables.t_order.key-generator.type=SNOWFLAKE

# 分片算法表达式
spring.shardingsphere.sharding.tables.t_order.table-strategy.inline.algorithm-expression=t_order$->{order_id % 2}


# 打印执行的数据库以及语句
spring.shardingsphere.props.sql.show=true
spring.main.allow-bean-definition-overriding=true


# mybatis-plus
mybatis-plus.mapper-locations=classpath:/mapper/*.xml
mybatis-plus.configuration.jdbc-type-for-null='null'


```
> 注意：数据库连接配置、mybatis-plus扫包路径，需要根据实际情况进行改变

以上的配置实现了分库分表，一下几点概念需要明白：

### 逻辑表
水平拆分的数据库（表）的相同逻辑和数据结构表的总称。例：订单数据根据主键尾数拆分为10张表，分别是t_order0到t_order9，他们的逻辑表名为t_order。

### 真实表
在分片的数据库中真实存在的物理表。即上个示例中的t_order0到t_order9。

### 数据节点
数据分片的最小单元。由数据源名称和数据表组成，例：ds0.t_order0。

### 分片键

用于分片的数据库字段，是将数据库(表)水平拆分的关键字段。例：将订单表中的订单主键的尾数取模分片，则订单主键为分片字段。 SQL中如果无分片字段，将执行全路由，性能较差。 除了对单分片字段的支持，ShardingSphere也支持根据多个字段进行分片。

### 分片算法

通过分片算法将数据分片，支持通过=、>=、<=、>、<、BETWEEN和IN分片。分片算法需要应用方开发者自行实现，可实现的灵活度非常高。

目前提供4种分片算法。由于分片算法和业务实现紧密相关，因此并未提供内置分片算法，而是通过分片策略将各种场景提炼出来，提供更高层级的抽象，并提供接口让应用开发者自行实现分片算法。

- 精确分片算法

对应PreciseShardingAlgorithm，用于处理使用单一键作为分片键的=与IN进行分片的场景。需要配合StandardShardingStrategy使用。

- 范围分片算法

对应RangeShardingAlgorithm，用于处理使用单一键作为分片键的BETWEEN AND、>、<、>=、<=进行分片的场景。需要配合StandardShardingStrategy使用。

- 复合分片算法

对应ComplexKeysShardingAlgorithm，用于处理使用多键作为分片键进行分片的场景，包含多个分片键的逻辑较复杂，需要应用开发者自行处理其中的复杂度。需要配合ComplexShardingStrategy使用。

- Hint分片算法

对应HintShardingAlgorithm，用于处理使用Hint行分片的场景。需要配合HintShardingStrategy使用。

### 分片策略

包含分片键和分片算法，由于分片算法的独立性，将其独立抽离。真正可用于分片操作的是分片键 + 分片算法，也就是分片策略。目前提供5种分片策略。

- 标准分片策略

对应StandardShardingStrategy。提供对SQL语句中的=, >, <, >=, <=, IN和BETWEEN AND的分片操作支持。StandardShardingStrategy只支持单分片键，提供PreciseShardingAlgorithm和RangeShardingAlgorithm两个分片算法。PreciseShardingAlgorithm是必选的，用于处理=和IN的分片。RangeShardingAlgorithm是可选的，用于处理BETWEEN AND, >, <, >=, <=分片，如果不配置RangeShardingAlgorithm，SQL中的BETWEEN AND将按照全库路由处理。

- 复合分片策略

对应ComplexShardingStrategy。复合分片策略。提供对SQL语句中的=, >, <, >=, <=, IN和BETWEEN AND的分片操作支持。ComplexShardingStrategy支持多分片键，由于多分片键之间的关系复杂，因此并未进行过多的封装，而是直接将分片键值组合以及分片操作符透传至分片算法，完全由应用开发者实现，提供最大的灵活度。

- 行表达式分片策略

对应InlineShardingStrategy。使用Groovy的表达式，提供对SQL语句中的=和IN的分片操作支持，只支持单分片键。对于简单的分片算法，可以通过简单的配置使用，从而避免繁琐的Java代码开发，如: t_user_$->{u_id % 8} 表示t_user表根据u_id模8，而分成8张表，表名称为t_user_0到t_user_7。

- Hint分片策略

对应HintShardingStrategy。通过Hint指定分片值而非从SQL中提取分片值的方式进行分片的策略。

- 不分片策略

对应NoneShardingStrategy。不分片的策略。

### SQL Hint
对于分片字段非SQL决定，而由其他外置条件决定的场景，可使用SQL Hint灵活的注入分片字段。例：内部系统，按照员工登录主键分库，而数据库中并无此字段。SQL Hint支持通过Java API和SQL注释(待实现)两种方式使用。

### 自增主键生成策略

通过在客户端生成自增主键替换以数据库原生自增主键的方式，做到分布式主键无重复。 采用UUID.randomUUID()的方式产生分布式主键。或者 SNOWFLAKE

## mybatis-plus

mybatis-plus极大的提高了开发效率，简单的配置和使用mybatis-plus


配置mybatis-plus的分页
```java
package com.winterchen.shardingspheredemo.configuration;


@EnableTransactionManagement
@Configuration
@MapperScan("com.winterchen.shardingspheredemo.dao")
public class MybatisPlusConfig {

    @Bean
    public PaginationInterceptor paginationInterceptor() {
        PaginationInterceptor paginationInterceptor = new PaginationInterceptor();
        // 设置请求的页面大于最大页后操作， true调回到首页，false 继续请求  默认false
        // paginationInterceptor.setOverflow(false);
        // 设置最大单页限制数量，默认 500 条，-1 不受限制
        // paginationInterceptor.setLimit(500);
        // 开启 count 的 join 优化,只针对部分 left join
        paginationInterceptor.setCountSqlParser(new JsqlParserCountOptimize());
        return paginationInterceptor;
    }
}
```

配置自定义的通用mapper

```java
package com.winterchen.shardingspheredemo.configuration;

import java.util.Map;

public interface MyBaseMapper<T> extends BaseMapper<T> {

    IPage<T> selectAllByCondition(Page<?> page, @Param("condition")Map<String, Object> condition);

    int deleteById(@Param("condition")Map<String, Object> condition);

}

```

## 代码

### 实体类

```java
package com.winterchen.shardingspheredemo.model;


@TableName("t_order")
public class OrderInfo {

    @TableId(value = "order_id")
    private Long orderId;

    @TableField(value = "order_name")
    private String orderName;

    @TableField(value = "order_status")
    private Integer orderStatus;

    @TableField(value = "user_id")
    private Long userId;

    //省略get/set
}

```

### Mapper

#### mapper

```java
package com.winterchen.shardingspheredemo.dao;


public interface OrderMapper extends MyBaseMapper<OrderInfo> {

    IPage<OrderInfo> selectAllByCondition(Page<?> page, @Param("condition") Map<String, Object> condition);

    int deleteById(@Param("condition")Map<String, Object> condition);

}

```

#### mapper xml

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd" >
<mapper namespace="com.winterchen.shardingspheredemo.dao.OrderMapper">
    
    <sql id="Base_Column_List">
        order_id, order_name, order_status, user_id
    </sql>
    
    <select id="selectAllByCondition" resultType="com.winterchen.shardingspheredemo.model.OrderInfo">
        select
            <include refid="Base_Column_List"/>
        from
           t_order
        <where>
            <if test="condition.userId != null">
                and user_id = #{condition.userId, jdbcType=BIGINT}
            </if>
            <if test="condition.orderId != null">
                and order_id = #{condition.orderId, jdbcType=BIGINT}
            </if>
            <if test="condition.orderName != null and condition.orderName != ''">
                and order_name like concat('%',#{condition.orderName,jdbcType=VARCHAR} ,'%')
            </if>
            <if test="condition.orderStatus != null">
                and order_status = #{condition.orderStatus, jdbcType=INTEGER}
            </if>
        </where>
    </select>

    <delete id="deleteById">
        delete from t_order where order_id = #{condition.orderId, jdbcType=BIGINT} and user_id = #{condition.userId, jdbcType=BIGINT}
    </delete>

</mapper>
```

### service

```java
package com.winterchen.shardingspheredemo.service;


public interface OrderService extends IService<OrderInfo> {

    @Override
    boolean save(OrderInfo entity);

    @Override
    boolean removeById(Serializable id);

    @Override
    boolean updateById(OrderInfo entity);

    IPage<OrderInfo> pageOrderInfos(Page<?> page, OrderInfo orderInfo);

}

```

```java
package com.winterchen.shardingspheredemo.service.impl;


@Service
public class OrderServiceImpl extends ServiceImpl<OrderMapper, OrderInfo> implements OrderService {


    @Override
    public boolean save(OrderInfo entity) {
        return super.save(entity);
    }

    @Override
    public boolean removeById(Serializable id) {
        return super.removeById(id);
    }

    @Override
    public boolean updateById(OrderInfo entity) {
        return super.updateById(entity);
    }


    @Override
    public IPage<OrderInfo> pageOrderInfos(Page<?> page, OrderInfo orderInfo) {
        Map<String, Object> map = new HashMap<>();
        map.put("userId", orderInfo.getUserId());
        map.put("orderId", orderInfo.getOrderId());
        map.put("orderName", orderInfo.getOrderName());
        map.put("orderStatus", orderInfo.getOrderStatus());
        return super.baseMapper.selectAllByCondition(page, map);
    }
}

```

### controller

```java
package com.winterchen.shardingspheredemo.controller;


@RestController
@RequestMapping("/api/v1/order")
public class OrderController {

    @Autowired
    private OrderService orderService;

    @PostMapping("")
    public boolean save(@RequestBody OrderInfo orderInfo) {
        return orderService.save(orderInfo);
    }

    @DeleteMapping("/{orderId}")
    public boolean deleteById(
            @PathVariable("orderId")
            Long id) {
        return orderService.removeById(id);
    }

    @PutMapping("/{orderId}")
    public boolean updateById(
            @PathVariable("orderId")
            Long orderId,
            @RequestBody OrderInfo orderInfo) {
        orderInfo.setOrderId(orderId);
        return orderService.updateById(orderInfo);
    }

    @GetMapping("/list")
    public IPage page(
            @RequestParam(name = "pageNum", required = false, defaultValue = "1")
                    Integer pageNum,
            @RequestParam(name = "pageSize", required = false, defaultValue = "10")
                    Integer pageSize,
            @RequestParam(name = "orderId", required = false)
            Long orderId,
            @RequestParam(name = "orderStatus", required = false)
            Integer orderStatus,
            @RequestParam(name = "orderName", required = false)
            String orderName) {
        Page<OrderInfo> page = new Page<>(pageNum,pageSize);
        OrderInfo orderInfo = new OrderInfo();
        orderInfo.setOrderId(orderId);
        orderInfo.setOrderName(orderName);
        orderInfo.setOrderStatus(orderStatus);
        return orderService.pageOrderInfos(page, orderInfo);
    }
}

```

### 启动类

```java
package com.winterchen.shardingspheredemo;



@SpringBootApplication
public class ShardingsphereDemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(ShardingsphereDemoApplication.class, args);
    }

}

```

以上就整合完毕了，可以使用postMan进行测试，测试截图就不展示了，后面会介绍关于读写分离的相关介绍，如果需要查看详细的介绍可以参考官方文档。

## 相关资源

- 官方源码地址：https://github.com/apache/shardingsphere
- 官方文档：https://shardingsphere.apache.org/document/current/cn/overview/
- mybatis-plus官方文档：https://mp.baomidou.com/guide/
