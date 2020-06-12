---
layout: post
title: 树莓派 docker 运行 redis
date: 2020-03-31 18:09
comments: true
tags: [docker,raspberry,redis,arm]
brief: [raspberry]
reward: true
categories: Raspberry
cover: https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200331210234.jpeg
---

> 树莓派上运行docker是不同于其他平台，树莓派属于arm32架构，经过前期的踩坑，在树莓派中运行docker镜像需要注意镜像对于doker的支持，在官方镜像搜索页是有系统架构作为删选的，如果需要运行arm32架构的镜像，需要使用对应的版本。


## 准备

- 树莓派4B
- docker
- docker-compose

## 使用镜像

```
arm32v7/redis
```

## 目录结构

```
.
│  .env
│  docker-compose.yml
│
└─redis
    └─config
           
 
```


## docker-compose.yml

```
version: '3'

services:
  redis:
    container_name: reids-docker        # 指定容器的名称
    image: arm32v7/redis                   # 指定镜像和版本,如果是树莓派，必须选择对应架构版本的镜像，不然无法运行
    restart: always
    command: --appendonly yes
    ports:
      - "6379:6379"
    volumes:
      - "${REDIS_DIR}/data:/data"           # 挂载数据目录
      - "${REDIS_DIR}/config/redis.conf:/usr/local/etc/redis/redis.conf"      # 挂载配置文件目录
```

## .env

```
REDIS_DIR=./redis
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
