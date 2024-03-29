---
layout: post
title: 用FastDFS一步步搭建文件管理系统(CentOS 7)
date:  2018-04-10 09:16
comments: true
tags: [FastDFS,Linux]
brief: "FastDFS"
reward: true
categories: FastDFS
keywords: FastDFS,Linux
cover: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046765592326.jpg
image: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046765942327.jpg
---
![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046766291606.jpg)
# 一、FastDFS介绍
开源地址：https://github.com/happyfish100
参考：[分布式文件系统FastDFS设计原理](http://blog.chinaunix.net/uid-20196318-id-4058561.html)
参考：[FastDFS分布式文件系统](http://www.cnblogs.com/Leo_wl/p/6731647.html)
<!--  more  -->
## 1.简介

FastDFS 是一个开源的高性能分布式文件系统（DFS）。 它的主要功能包括：文件存储，文件同步和文件访问，以及高容量和负载平衡。主要解决了海量数据存储问题，特别适合以中小文件（建议范围：4KB < file_size <500MB）为载体的在线服务。

FastDFS 系统有三个角色：跟踪服务器(Tracker Server)、存储服务器(Storage Server)和客户端(Client)。

　　**Tracker Server**：跟踪服务器，主要做调度工作，起到均衡的作用；负责管理所有的 storage server和 group，每个 storage 在启动后会连接 Tracker，告知自己所属 group 等信息，并保持周期性心跳。

　　**Storage Server**：存储服务器，主要提供容量和备份服务；以 group 为单位，每个 group 内可以有多台 storage server，数据互为备份。

　　**Client**：客户端，上传下载数据的服务器，也就是我们自己的项目所部署在的服务器。
　　
　　![服务基本架构](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046457404302.png)
　　
## 2、FastDFS的存储策略
为了支持大容量，存储节点（服务器）采用了分卷（或分组）的组织方式。存储系统由一个或多个卷组成，卷与卷之间的文件是相互独立的，所有卷的文件容量累加就是整个存储系统中的文件容量。一个卷可以由一台或多台存储服务器组成，一个卷下的存储服务器中的文件都是相同的，卷中的多台存储服务器起到了冗余备份和负载均衡的作用。

在卷中增加服务器时，同步已有的文件由系统自动完成，同步完成后，系统自动将新增服务器切换到线上提供服务。当存储空间不足或即将耗尽时，可以动态添加卷。只需要增加一台或多台服务器，并将它们配置为一个新的卷，这样就扩大了存储系统的容量。

## 3、FastDFS的上传过程

FastDFS向使用者提供基本文件访问接口，比如upload、download、append、delete等，以客户端库的方式提供给用户使用。

Storage Server会定期的向Tracker Server发送自己的存储信息。当Tracker Server Cluster中的Tracker Server不止一个时，各个Tracker之间的关系是对等的，所以客户端上传时可以选择任意一个Tracker。

当Tracker收到客户端上传文件的请求时，会为该文件分配一个可以存储文件的group，当选定了group后就要决定给客户端分配group中的哪一个storage server。当分配好storage server后，客户端向storage发送写文件请求，storage将会为文件分配一个数据存储目录。然后为文件分配一个fileid，最后根据以上的信息生成文件名存储文件。


![FastDFS的上传过程](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046457665865.png)

## 4、FastDFS的文件同步
写文件时，客户端将文件写至group内一个storage server即认为写文件成功，storage server写完文件后，会由后台线程将文件同步至同group内其他的storage server。

每个storage写文件后，同时会写一份binlog，binlog里不包含文件数据，只包含文件名等元信息，这份binlog用于后台同步，storage会记录向group内其他storage同步的进度，以便重启后能接上次的进度继续同步；进度以时间戳的方式进行记录，所以最好能保证集群内所有server的时钟保持同步。

storage的同步进度会作为元数据的一部分汇报到tracker上，tracke在选择读storage的时候会以同步进度作为参考。

## 5、FastDFS的文件下载
客户端uploadfile成功后，会拿到一个storage生成的文件名，接下来客户端根据这个文件名即可访问到该文件。
![FastDFS的文件下载过程](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046457879129.png)

跟upload file一样，在downloadfile时客户端可以选择任意tracker server。tracker发送download请求给某个tracker，必须带上文件名信息，tracke从文件名中解析出文件的group、大小、创建时间等信息，然后为该请求选择一个storage用来服务读请求。

# 二、安装FastDFS环境
## 0、前言
操作环境：CentOS7 X64，以下操作都是单机环境。

我把所有的安装包下载到/softpackages/下，解压到当前目录。

先做一件事，修改hosts，将文件服务器的ip与域名映射(单机TrackerServer环境)，因为后面很多配置里面都需要去配置服务器地址，ip变了，就只需要修改hosts即可。

```
# vim /etc/hosts

增加如下一行，这是我的IP
118.25.36.41 luischen.cn

如果要本机访问虚拟机，在C:\Windows\System32\drivers\etc\hosts中同样增加一行
```

## 1、下载安装 libfastcommon
libfastcommon是从 FastDFS 和 FastDHT 中提取出来的公共 C 函数库，基础环境，安装即可 。
### ① 下载libfastcommon
```
# wget https://github.com/happyfish100/libfastcommon/archive/V1.0.7.tar.gz
```

### ② 解压
```
# tar -zxvf V1.0.7.tar.gz
# cd libfastcommon-1.0.7
```

### ③ 编译、安装
```
# ./make.sh
# ./make.sh install
```

### ④ libfastcommon.so 安装到了/usr/lib64/libfastcommon.so，但是FastDFS主程序设置的lib目录是/usr/local/lib，所以需要创建软链接。

```
# ln -s /usr/lib64/libfastcommon.so /usr/local/lib/libfastcommon.so
# ln -s /usr/lib64/libfastcommon.so /usr/lib/libfastcommon.so
# ln -s /usr/lib64/libfdfsclient.so /usr/local/lib/libfdfsclient.so
# ln -s /usr/lib64/libfdfsclient.so /usr/lib/libfdfsclient.so 
```

## 2、下载安装FastDFS

### ① 下载FastDFS
```
# wget https://github.com/happyfish100/fastdfs/archive/V5.05.tar.gz

```

### ② 解压
```
# tar -zxvf V5.05.tar.gz
# cd fastdfs-5.05
```

### ③ 编译、安装
```
# ./make.sh
# ./make.sh install
```

### ④ 默认安装方式安装后的相应文件与目录
* A、服务脚本：


```
/etc/init.d/fdfs_storaged
/etc/init.d/fdfs_tracker

```
* B、配置文件（这三个是作者给的样例配置文件） :


```
/etc/fdfs/client.conf.sample
/etc/fdfs/storage.conf.sample
/etc/fdfs/tracker.conf.sample

```

* C、命令工具在 /usr/bin/ 目录下：

```
fdfs_appender_test
fdfs_appender_test1
fdfs_append_file
fdfs_crc32
fdfs_delete_file
fdfs_download_file
fdfs_file_info
fdfs_monitor
fdfs_storaged
fdfs_test
fdfs_test1
fdfs_trackerd
fdfs_upload_appender
fdfs_upload_file
stop.sh
restart.sh
```

### ⑤ FastDFS 服务脚本设置的 bin 目录是 /usr/local/bin， 但实际命令安装在 /usr/bin/ 下。

* 建立 /usr/bin 到 /usr/local/bin 的软链接

```
# ln -s /usr/bin/fdfs_trackerd   /usr/local/bin
# ln -s /usr/bin/fdfs_storaged   /usr/local/bin
# ln -s /usr/bin/stop.sh         /usr/local/bin
# ln -s /usr/bin/restart.sh      /usr/local/bin

```

## 3、配置FastDFS跟踪器(Tracker)

配置文件详细说明参考：[FastDFS 配置文件详解](http://bbs.chinaunix.net/forum.php?mod=viewthread&tid=1941456&extra=page%3D1%26filter%3Ddigest%26digest%3D1)

### ① 进入 /etc/fdfs，复制 FastDFS 跟踪器样例配置文件 tracker.conf.sample，并重命名为 tracker.conf。

```
# cd /etc/fdfs
# cp tracker.conf.sample tracker.conf
# vim tracker.conf
```

### ② 编辑tracker.conf ，修改下，其它的默认即可。

```
# 配置文件是否不生效，false 为生效
disabled=false

# 提供服务的端口
port=22122

# Tracker 数据和日志目录地址(根目录必须存在,子目录会自动创建)----------【需要修改】
base_path=/data/fastdfs/tracker

# HTTP 服务端口----------【需要修改】
http.server_port=80

```

### ③ 创建tracker基础数据目录，即base_path对应的目录

```
mkdir -p /data/fastdfs/tracker
```

### ④ 防火墙中打开跟踪端口（默认的22122）

centos7的防火墙由firewalld进行管理

* 查看状态：``systemctl status firewalld``
* 开启：``systemctl start firewalld``
* 关闭:  ``systemctl stop firewalld``
* 添加开放IP：``firewall-cmd --permanent --zone=public --add-port=22122/tcp``
* 重启： ``firewall-cmd --reload``

查看服务的运行状态：``netstat -unltp|grep fdfs``

### ⑤ 启动Tracker

初次成功启动，会在 /data/fastdfs/tracker/ (配置的base_path)下创建 data、logs 两个目录。

```
可以用这种方式启动
# /etc/init.d/fdfs_trackerd start

也可以用这种方式启动，前提是上面创建了软链接，后面都用这种方式
# service fdfs_trackerd start
```

查看 FastDFS Tracker 是否已成功启动 ，22122端口正在被监听，则算是Tracker服务安装成功

```
# netstat -unltp|grep fdfs
```

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046457980987.png)

关闭Tracker命令：

```
# service fdfs_trackerd stop
```

### ⑥ 设置Tracker开机启动

```
# chkconfig fdfs_trackerd on

或者：
# vim /etc/rc.d/rc.local
加入配置：
/etc/init.d/fdfs_trackerd start 
```

### ⑦ tracker server 目录及文件结构

Tracker服务启动成功后，会在base_path下创建data、logs两个目录。目录结构如下：

```
${base_path}
  |__data
  |   |__storage_groups.dat：存储分组信息
  |   |__storage_servers.dat：存储服务器列表
  |__logs
  |   |__trackerd.log： tracker server 日志文件 
```

## 4、配置 FastDFS 存储 (Storage)

### ① 进入 /etc/fdfs 目录，复制 FastDFS 存储器样例配置文件 storage.conf.sample，并重命名为 storage.conf

```
# cd /etc/fdfs
# cp storage.conf.sample storage.conf
# vim storage.conf
```

### ② 编辑storage.conf
修改以下，其它的默认即可。

```
# 配置文件是否不生效，false 为生效
disabled=false 

# 指定此 storage server 所在 组(卷)
group_name=group1

# storage server 服务端口
port=23000

# 心跳间隔时间，单位为秒 (这里是指主动向 tracker server 发送心跳)
heart_beat_interval=30

# Storage 数据和日志目录地址(根目录必须存在，子目录会自动生成)----------【需要修改】
base_path=/data/fastdfs/storage

# 存放文件时 storage server 支持多个路径。这里配置存放文件的基路径数目，通常只配一个目录。
store_path_count=1


# 逐一配置 store_path_count 个路径，索引号基于 0。
# 如果不配置 store_path0，那它就和 base_path 对应的路径一样。----------【需要修改】
store_path0=/data/fastdfs/file

# FastDFS 存储文件时，采用了两级目录。这里配置存放文件的目录个数。 
# 如果本参数只为 N（如： 256），那么 storage server 在初次运行时，会在 store_path 下自动创建 N * N 个存放文件的子目录。
subdir_count_per_path=256

# tracker_server 的列表 ，会主动连接 tracker_server
# 有多个 tracker server 时，每个 tracker server 写一行----------【需要修改】
tracker_server=118.25.36.41:22122

# 允许系统同步的时间段 (默认是全天) 。一般用于避免高峰同步产生一些问题而设定。
sync_start_time=00:00
sync_end_time=23:59
# 访问端口----------------------------------------【需要修改】
http.server_port=80
```

### ③ 创建Storage基础数据目录，对应base_path目录

```
# mkdir -p /data/fastdfs/storage

# 这是配置的store_path0路径
# mkdir -p /data/fastdfs/file

```

### ④ 防火墙中打开存储器端口（默认的 23000）

```
# 添加开放IP：
firewall-cmd --permanent --zone=public --add-port=23000/tcp
# 重启： 
firewall-cmd --reload
```

### ⑤ 启动 Storage

启动Storage前确保Tracker是启动的。初次启动成功，会在 /data/fastdfs/storage 目录下创建 data、 logs 两个目录。

```
可以用这种方式启动
# /etc/init.d/fdfs_storaged start

也可以用这种方式，后面都用这种
# service fdfs_storaged start
```

查看 Storage 是否成功启动，23000 端口正在被监听，就算 Storage 启动成功。

```
# netstat -unltp|grep fdfs
```

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046458057926.png)

关闭Storage命令：

```
# service fdfs_storaged stop
```

查看Storage和Tracker是否在通信：

```
/usr/bin/fdfs_monitor /etc/fdfs/storage.conf
```

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046458093927.png)


###  ⑥ 设置 Storage 开机启动

```
# chkconfig fdfs_storaged on

或者：
# vim /etc/rc.d/rc.local
加入配置：
/etc/init.d/fdfs_storaged start
```

### ⑦ Storage 目录

同 Tracker，Storage 启动成功后，在base_path 下创建了data、logs目录，记录着 Storage Server 的信息。

在 store_path0 目录下，创建了N*N个子目录：

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046458151928.png)


## 5、文件上传测试

### ① 修改 Tracker 服务器中的客户端配置文件 

```
# cd /etc/fdfs
# cp client.conf.sample client.conf
# vim client.conf
```

修改如下配置即可，其它默认。

```
# Client 的数据和日志目录
base_path=/data/fastdfs/client

# Tracker端口
tracker_server=118.25.36.41:22122
```

### ② 上传测试

首先需要创建client目录

```
mkdir -p /data/fastdfs/client
```

 在linux内部执行如下命令上传 namei.jpeg 图片
 
 ```
 # /usr/bin/fdfs_upload_file /etc/fdfs/client.conf storage.conf
 ```

 上传成功后返回文件ID号：
 
 ```
 group1/M00/00/00/Cmlg2FrLU9eAVJ-ZAAAejzOgbzU97.conf
 ```
 
![上传成功](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046458201073.png)
 
 返回的文件ID由group、存储目录、两级子目录、fileid、文件后缀名（由客户端指定，主要用于区分文件类型）拼接而成。
 
 ![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046766779695.jpg)
 
# 三、安装Nginx

上面将文件上传成功了，但我们无法下载。因此安装Nginx作为服务器以支持Http方式访问文件。同时，后面安装FastDFS的Nginx模块也需要Nginx环境。

Nginx只需要安装到StorageServer所在的服务器即可，用于访问文件。我这里由于是单机，TrackerServer和StorageServer在一台服务器上。



## 1、安装nginx所需环境

### ① gcc 安装

```
# yum install gcc-c++
```

### ② PCRE pcre-devel 安装

```
# yum install -y pcre pcre-devel
```

### ③ zlib 安装

```
# yum install -y zlib zlib-devel
```

### ④ OpenSSL 安装

```
# yum install -y openssl openssl-devel
```

## 2、安装Nginx

### ① 下载nginx

```
# wget -c https://nginx.org/download/nginx-1.12.1.tar.gz
```

### ② 解压

```
# tar -zxvf nginx-1.12.1.tar.gz
# cd nginx-1.12.1
```

### ③ 使用默认配置

```
# ./configure
```

### ④ 编译、安装

```
# make
# make install
```

### ⑤ 启动nginx

```
# cd /usr/local/nginx/sbin/
# ./nginx 

其它命令
# ./nginx -s stop
# ./nginx -s quit
# ./nginx -s reload
```

### ⑥ 设置开机启动

```

# vim /etc/rc.local

添加一行：
/usr/local/nginx/sbin/nginx

# 设置执行权限
# chmod 755 /etc/rc.local
```

### ⑦ 查看nginx的版本及模块

```
/usr/local/nginx/sbin/nginx -V
```

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046458483555.png)

### ⑧ 防火墙中打开Nginx端口（默认的 80） 

添加后就能在本机使用80端口访问了。

```
# 添加开放IP：
firewall-cmd --permanent --zone=public --add-port=80/tcp
# 重启： 
firewall-cmd --reload
```


## 3、访问文件

简单的测试访问文件

### ① 修改nginx.conf

```
# vim /usr/local/nginx/conf/nginx.conf

添加如下行，将 /group1/M00 映射到 /data/fastdfs/file/data
location /group1/M00 {
    alias /data/fastdfs/file/data;
}

# 重启nginx
# /usr/local/nginx/sbin/nginx -s reload
```

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046458524552.png)

② 在浏览器访问之前上传的图片、成功。

http://118.25.36.41/group1/M00/00/00/Cmlg2FrLU9eAVJ-ZAAAejzOgbzU97.conf


# 四、FastDFS 配置 Nginx 模块

## 1、安装配置Nginx模块

### ① fastdfs-nginx-module 模块说明

FastDFS 通过 Tracker 服务器，将文件放在 Storage 服务器存储， 但是同组存储服务器之间需要进行文件复制， 有同步延迟的问题。

　　假设 Tracker 服务器将文件上传到了 192.168.51.128，上传成功后文件 ID已经返回给客户端。

　　此时 FastDFS 存储集群机制会将这个文件同步到同组存储 192.168.51.129，在文件还没有复制完成的情况下，客户端如果用这个文件 ID 在 192.168.51.129 上取文件,就会出现文件无法访问的错误。

　　而 fastdfs-nginx-module 可以重定向文件链接到源服务器取文件，避免客户端由于复制延迟导致的文件无法访问错误。
　　
### ② 下载 fastdfs-nginx-module、解压

```
# 这里为啥这么长一串呢，因为最新版的master与当前nginx有些版本问题。
# wget https://github.com/happyfish100/fastdfs-nginx-module/archive/5e5f3566bbfa57418b5506aaefbe107a42c9fcb1.zip

# 解压
# unzip 5e5f3566bbfa57418b5506aaefbe107a42c9fcb1.zip

# 重命名
# mv fastdfs-nginx-module-5e5f3566bbfa57418b5506aaefbe107a42c9fcb1  fastdfs-nginx-module-master
```

### ③ 配置Nginx

在nginx中添加模块

```
# 先停掉nginx服务
# /usr/local/nginx/sbin/ngix -s stop

进入解压包目录
# cd /softpackages/nginx-1.12.1/

# 添加模块
# ./configure --add-module=../fastdfs-nginx-module-master/src

重新编译、安装
# make && make install
```

###  ④ 查看Nginx的模块

```
# /usr/local/nginx/sbin/nginx -V
```

有下面这个就说明添加模块成功

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046458581094.png)

### ⑤ 复制 fastdfs-nginx-module 源码中的配置文件到/etc/fdfs 目录， 并修改

```
# cd /softpackages/fastdfs-nginx-module-master/src

# cp mod_fastdfs.conf /etc/fdfs/
```

修改如下配置，其它默认

```
# cd /softpackages/fastdfs-nginx-module-master/src

# cp mod_fastdfs.conf /etc/fdfs/
```

修改如下配置，其它默认

```
# 连接超时时间
connect_timeout=10

# Tracker Server
tracker_server=118.25.36.41:22122

# StorageServer 默认端口
storage_server_port=23000

# 如果文件ID的uri中包含/group**，则要设置为true
url_have_group_name = true

# Storage 配置的store_path0路径，必须和storage.conf中的一致
store_path0=/data/fastdfs/file
```

### ⑥ 复制 FastDFS 的部分配置文件到/etc/fdfs 目录

```
# cd /softpackages/fastdfs-5.05/conf/

# cp anti-steal.jpg http.conf mime.types /etc/fdfs/
```

### ⑦ 配置nginx，修改nginx.conf

```
# vim /usr/local/nginx/conf/nginx.conf
```

修改配置，其它的默认

在80端口下添加fastdfs-nginx模块

```
location ~/group([0-9])/M00 {
    ngx_fastdfs_module;
}
```

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046458635093.png)

**注意：**
listen 80 端口值是要与 /etc/fdfs/storage.conf 中的 http.server_port=80 (前面改成80了)相对应。如果改成其它端口，则需要统一，同时在防火墙中打开该端口。

　　location 的配置，如果有多个group则配置location ~/group([0-9])/M00 ，没有则不用配group。
　　
### ⑧ 在/data/fastdfs/file 文件存储目录下创建软连接，将其链接到实际存放数据的目录，这一步可以省略。

```
# ln -s /data/fastdfs/file/data/ /data/fastdfs/file/data/M00 

```

### ⑨ 启动nginx

```
# /usr/local/nginx/sbin/nginx
```

打印处如下就算配置成功

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046458687094.png)

### ⑩ 在地址栏访问

能下载文件就算安装成功。注意和第三点中直接使用nginx路由访问不同的是，这里配置 fastdfs-nginx-module 模块，可以重定向文件链接到源服务器取文件。

http://118.25.36.41/group1/M00/00/00/Cmlg2FrLU9eAVJ-ZAAAejzOgbzU97.conf

 

最终部署结构图(盗的图)：可以按照下面的结构搭建环境。
![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046458722093.png)

以上




原作者：bojiangzhou
原出处：http://www.cnblogs.com/chiangchou/
　　

 














