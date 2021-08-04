---
layout: post
title: 树莓派 docker 运行 mysql
date: 2020-03-31 18:03
comments: true
tags: [docker,raspberry,mysql,arm]
brief: [raspberry]
reward: true
keywords: docker,raspberry,mysql,arm
categories: Raspberry
cover: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046443136295.png
image: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046443720062.png
---

> 树莓派上运行docker是不同于其他平台，树莓派属于arm32架构，经过前期的踩坑，在树莓派中运行docker镜像需要注意镜像对于doker的支持，在官方镜像搜索页是有系统架构作为删选的，如果需要运行arm32架构的镜像，需要使用对应的版本。


## 准备

- 树莓派4B
- docker
- docker-compose

## 使用镜像

```
hypriot/rpi-mysql
```

## 目录结构

```
.
│  .env
│  docker-compose.yml
│
└─mysql
    ├─config
    │      my.cnf
    │
    └─data
```


## docker-compose.yml

```
version: '3'

services:
  mysql-db:
    container_name: mysql-docker        # 指定容器的名称
    image: hypriot/rpi-mysql                   # 指定镜像和版本
    ports:
      - "3306:3306"
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_ROOT_HOST: ${MYSQL_ROOT_HOST}
    volumes:
      - "${MYSQL_DIR}/data:/var/lib/mysql"           # 挂载数据目录
      - "${MYSQL_DIR}/config:/etc/mysql/conf.d"      # 挂载配置文件目录
```

## .env

```
MYSQL_ROOT_PASSWORD=root
MYSQL_ROOT_HOST=%

MYSQL_DIR=./mysql
```

## my.cnf

```
[mysqld]
character-set-server=utf8mb4
default-time-zone='+8:00'
innodb_rollback_on_timeout='ON'
max_connections=500
innodb_lock_wait_timeout=500
```

## 编译

在根目录(docker-compose.yml所在目录)

启动

```
dokcer-compose up -d
```

停止

```
docker-compose stop
```

## 源码地址

[源码地址](https://github.com/WinterChenS/docker-compose-simple)

