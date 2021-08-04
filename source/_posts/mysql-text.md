---
layout: post
title: 解决Mysql存入大量TEXT类型的数据报错
date: 2017-09-26 16:37
comments: true
tags: [mysql]
brief: "学习一下"
reward: true
categories: mysql
keywords: mysql
cover: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039845.jpg
image: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039845.jpg
---

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039845.jpg)
主要的原因是因为max_sort_length的默认值为1024,=
解决办法：该参数是动态参数，任何客户端都可以在Mysql数据库运行时更改该参数的值，例如：
1.首先应该查询一下这个参数的默认值为多少
```
mysql> SELECT @@global.max_sort_length;
```
<!-- more -->
2.然后去设置这个值：

```
mysql> SET GLOBAL max_sort_length=2048;  //2048这个数值由你了
```
3.然后再查询一下这个参数的默认值：
```
mysql> SELECT @@global.max_sort_length;
```
以上问题就解决了
