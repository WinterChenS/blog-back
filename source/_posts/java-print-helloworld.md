---
layout: post
title: java优雅的输出helloWorld
date: 2017-09-25 22:41
comments: true
tags: [java]
brief: "学习一下"
reward: true
categories: java基础
keywords: java
cover: http://img.winterchen.com/WX20180328-090749@2x.png
image: http://img.winterchen.com/WX20180328-090749@2x.png
---
![](http://img.winterchen.com/WX20180328-090749@2x.png)
在java中很优雅的输出helloworld，可以试一试
<!-- more -->
```java
public class Test{
    public static void main(String[] args) {
    		System.out.println(randomString(-229985452) + " " + randomString(-147909649));
    	}
    	
    	public static String randomString(int seed){
    		Random rand = new Random(seed);
    		StringBuilder sb = new StringBuilder();
    		while(true){
    			int n = rand.nextInt(27);
    			if(n==0) break;
    			sb.append((char)('`'+n));
    				
    		}
    		return sb.toString();
    	}
}

```