---
layout: post
title: jenkins+docker自动化运维发布
date: 2020-03-14 19:03
comments: true
tags: [docker,jenkins,DevOps]
brief: [DevOps]
reward: true
categories: DevOps
keywords: DevOps,docker,jenkins
cover: http://img.winterchen.com/photo-1556009514-e39e4715fcde.jpeg
image: http://img.winterchen.com/photo-1556009514-e39e4715fcde.jpeg
---

面对微服务越来越繁杂的开发和运维，自动化部署的出现无异于雪中送炭，今天就开始一步一步搭建自动化部署平台，基于Docker。

![jenkins持续交付流程图](http://img.winterchen.com/20200613210704.png)


本次搭建的前提；
* Docker

## 安装Docker

运行命令：
```shell script
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
```
安装所需的软件包。 yum-utils提供了yum-config-manager实用程序，devicemapper存储驱动程序需要device-mapper-persistent-data和lvm2

```shell script
sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
```

设置稳定的镜像仓库
```shell script
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```
安装最新版docker
```shell script
sudo yum install docker-ce docker-ce-cli containerd.io
```

## docker加速

```shell script
vim /etc/docker/daemon.json 
```
如果不存在daemon.json文件则新建一个

daemon.json
```json
{
    "registry-mirrors":["https://docker.mirrors.ustc.edu.cn"]
}
```
重启守护进程
```shell script
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### docker常用命令

```shell script
# 进入容器
docker exec -it <containerId> /bin/bash
# 查看容器日志
docker logs -f <containerId>
```

## jenkins和docker私有仓库registry环境安装

安装jenkins
```shell script
docker run --name devops-jenkins --user=root -p 8080:8080 -p 50000:50000 -v /opt/data/jenkins_home:/var/jenkins_home -d jenkins/jenkins:lts
```
安装私有仓库
```shell script
docker run --name devops-registry -p 5000:5000 -v /opt/devdata/registry:/var/lib/registry -d registry
```

## jenkins 配置

### 初始化jenkins及安装插件

启动完jenkins后通过浏览器输入地址http://部署jenkins主机IP:端口

![](http://img.winterchen.com/20200613210733.png)

根据提示从输入administrator password 或者可以通过启动日志

```shell script
docker logs devops-jenkins
```

查看这个password 如：

![](http://img.winterchen.com/20200613210753.png)

选择安装插件方式，这里我是默认第一个

![](http://img.winterchen.com/20200613210813.png)

进入插件安装界面，连网等待插件安装

![](http://img.winterchen.com/20200613210832.png)

安装完插件后，进入创建管理员界面

![](http://img.winterchen.com/20200613210851.png)

输入完管理员账号后，点击continue as admin 进入管理界面点击系统管理-插件管理中安装docker构建插件和角色管理插件
![](http://img.winterchen.com/20200613210957.png)

安装docker构建插件，在可选插件中查找docker build step plugin
![](http://img.winterchen.com/20200613211017.png)

安装角色管理插件，在可选插件中查找Role-based Authorization Strategy
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314203553.png)

安装SSH插件，用于构建成功后执行远端服务器脚本从docker本地仓库获取镜像后发布新版本
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314203620.png)

安装 Email Extension Plugin 插件，配置自动发送邮件
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314203648.png)

## 配置jenkins属性及相关权限

### jenkins属性

点击系统管理->Global Tool Configuration->找到jdk点击新增按钮(自动安装请先到Oracle注册账号)

![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314203733.png)

配置git
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314211249.png)

点击系统管理->Global Tool Configuration->找到maven点击新增按钮

![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314203755.png)

点击系统管理->系统设置
配置SSH

![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314203926.png)

配置docker

![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314204005.png)

设置docker主机可以被远程访问

```shell script
vim /usr/lib/systemd/system/docker.service
在ExecStart=/usr/bin/docker daemon 后追加 -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock

#如：
ExecStart=/usr/bin/docker daemon -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
```
重启docker
```shell script
sudo systemctl daemon-reload
sudo systemctl restart docker
```

重新启动jenkins容器
```shell script
# 查看所有的容器
docker container ls -a
# 找到jenkins和私有仓库的containerId，启动
docker container start <container Id>
```

配置邮件

![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314204050.png)

## jenkins权限

1. 选择系统管理->Configuration Global Security（全局安全设置）->进入选择启用安全：
   TCP port for JNLP agents ->禁用，访问控制-安全域->jenkins专有用户数据库，访问控制-授权策略->Role-Based Strategy 如：
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314204232.png)

2. 选择系统管理->Manage and Assign Roles->Manage Roles：

* 添加Global Roles(admin、member、ops、others)，
  设置全局角色（全局角色可以对jenkins系统进行设置与项目的操作）
  admin:对整个jenkins都可以进行操作
  ops:可以对所有的job进行管理
  other/member:只有读的权限

* 添加project Roles(dmp-manager、dmp-view、tsc-manager、tsc-view)并且给添加的角色分配如下权限

![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314204349.png)

* 注意：在添加project Roles时，如果想让不同的用户看到不同的job,必须设置Pattern,如上dmp_manager角色就只能查看以dmp开头的job,Pattern规则必须是“dmp.”，注意是以“.”结尾的匹配规则，tsc亦是如此。

3. 选择系统管理->管理用户:新建几个管理员用户如：dmpadmin、tscadmin
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314204435.png)

4. 选择系统管理->Manage and Assign Roles->Assign Relos:把第三步的用户加到user/group中并授于对应的角色权限 如：

![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314204502.png)

## 创建-编译-打包-上传docker镜像任务-执行远端脚本从私有仓库获取镜像发布新版本-发布完成发送邮件推送

### 新建任务
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314204615.png)

### 源码管理
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314204729.png)
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314204820.png)

### 构建触发器
如果没有此项，请安装该插件 Generic Webhook Trigger
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314205034.png)

![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314205637.png)

#### github创建webhook

http://用户名:webToken@Jenkins服务器地址:端口/generic-webhook-trigger/invoke
如http://admin:dsfadfadsfaf@192.168.1.1:8080/generic-webhook-trigger/invoke

![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314205142.png)
点击添加webhook
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314205227.png)
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200315114955.png)
图中的token和上面构建触发器中填写的token是一致的，如果都没有构建器中没有填写，那么这边可以不用添加

## 构建

1、maven 构建项目
2、构建docker镜像
3、推送docker镜像

#### maven 构建镜像
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314210251.png)
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314210359.png)
#### 构建和推送docker镜像
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314210526.png)

#### SSH执行远端服务器脚本运行最新镜像
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314210742.png)

## 构建后操作

### 发送邮件推送

![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314210917.png)

## 验证构建

见证奇迹的时候到了

点击立即构建

![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314211006.png)
![](https://raw.githubusercontent.com/WinterChenS/imgrpo/develop/blog/20200314211041.png)

## my-site-run.sh

```shell script
docker pull 118.25.36.41:5000/winterchen/my-site:1.0.0-RELEASE

docker stop 118.25.36.41:5000/winterchen/my-site:1.0.0-RELEASE

docker rm 118.25.36.41:5000/winterchen/my-site:1.0.0-RELEASE

docker run 118.25.36.41:5000/winterchen/my-site:1.0.0-RELEASE
```




  








