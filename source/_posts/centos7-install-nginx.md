---
layout: post
title: 如何在CentOS 7上安装和配置Nginx
date:  2018-05-30 09:53
comments: true
tags: [Linux,nginx,centos7]
brief: "Linux"
reward: true
categories: Linux
keywords: Linux,nginx,centos7
cover: https://images.unsplash.com/photo-1526740048776-83b7bbf6860d?ixlib=rb-0.3.5&s=61f5e69ba90a009c860fa2d47ce5da3d&auto=format&fit=crop&w=2104&q=80
image: https://images.unsplash.com/photo-1526740048776-83b7bbf6860d?ixlib=rb-0.3.5&s=61f5e69ba90a009c860fa2d47ce5da3d&auto=format&fit=crop&w=2104&q=80
---


![](http://img.winterchen.com/ddfc08f6f5a1adfab32e8c2b8a28069f.jpg)

如何在centOS7中安装和配置nginx呢？

<!-- more -->
## 1.安装CentOS 7 EPEL仓库

```
sudo yum install epel-release
```

## 2.安装Nginx

现在Nginx存储库已经安装在您的服务器上，使用以下`yum`命令安装Nginx ：

```
sudo yum install nginx
```

在对提示回答yes后，Nginx将在服务器上完成安装。

## 3.启动Nginx

Nginx不会自行启动。要运行Nginx，请输入：

```
sudo systemctl start nginx
```

如果您正在运行防火墙，请运行以下命令以允许HTTP和HTTPS通信：

```
sudo firewall-cmd --permanent --zone=public --add-service=http 
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload
```

打开浏览器输入ip地址看到nginx的首页就说明你启动成功了

## 4.设置开机启动

```
sudo systemctl enable nginx
```

## 5.配置nginx

使用`yum`进行安装的nginx的配置文件在`/etc/nginx/nginx.conf`

```
vim /etc/nginx/nginx.conf
```

### nginx.conf:

```
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;

#nginx进程数，建议设置为等于CPU总核心数。
worker_processes auto;

#全局错误日志定义类型，[ debug | info | notice | warn | error | crit ]
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;#进程pid文件

# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    #单个进程最大连接数（最大连接数=连接数*进程数）
    #根据硬件调整，和前面工作进程配合起来用，尽量大，但是别把cpu跑到100%就行。每个进程允许的最多连接数，理论上每台nginx服务器的最大连接数为。	
    worker_connections 1024;
}

#设定http服务器，利用它的反向代理功能提供负载均衡支持
http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

		#开启高效文件传输模式，sendfile指令指定nginx是否调用sendfile函数来输出文件，对于普通应用设为 on，如果用来进行下载等应用磁盘IO重负载应用，可设置为off，以平衡磁盘与网络I/O处理速度，降低系统的负载。注意：如果图片显示不正常把这个改成off。
    #sendfile指令指定 nginx 是否调用sendfile 函数（zero copy 方式）来输出文件，对于普通应用，必须设为on。如果用来进行下载等应用磁盘IO重负载应用，可设置为off，以平衡磁盘与网络IO处理速度，降低系统uptime。
    sendfile            on;
    
    #此选项允许或禁止使用socke的TCP_CORK的选项，此选项仅在使用sendfile的时候使用
    tcp_nopush          on;
    tcp_nodelay         on;
    
    #长连接超时时间，单位是秒
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;
	
  	#虚拟主机的配置
    server {
    		#监听端口
        listen       80 default_server;
        listen       [::]:80 default_server;
        
        #域名可以有多个，用空格隔开
        server_name  luischen.cn;
       # root         /usr/share/nginx/html;
       # 重定向至https（按照需求）
        rewrite ^(.*)$  https://$host$1 permanent;
        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }

# Settings for a TLS enabled server.

    server {
    		# 监听433端口
        listen       443 ssl http2 default_server;
        listen       [::]:443 ssl http2 default_server;
        server_name  luischen.cn;
        #root         /usr/share/nginx/html;
				# ssl证书
        ssl_certificate "/etc/nginx/1_luischen.cn_bundle.crt";
        ssl_certificate_key "/etc/nginx/2_luischen.cn.key";
        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout  10m;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;
        
        #以下是一些反向代理的配置，可选。
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        #后端的Web服务器可以通过X-Forwarded-For获取用户真实IP
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
#        # Load configuration files for the default server block.
#        include /etc/nginx/default.d/*.conf;
#					
        location / {
         # 需要代理的端口-也就是nginx指向本地的端口
         proxy_pass http://127.0.0.1:8091;
         # 超时时间
         proxy_connect_timeout 600;
         proxy_read_timeout 600;
        }
        
        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }
 }
```


## 6.nginx启动和停止命令

启动
```
sudo systemctl start nginx
```

停止
```
sudo systemctl stop nginx
```















