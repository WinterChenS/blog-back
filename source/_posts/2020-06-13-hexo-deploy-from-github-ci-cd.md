---
layout: post
title: 如何使用 GitHub Actions 实现 Hexo 博客的 CICD
date: 2020-06-13 22:27
comments: true
tags: [hexo,github,github-actions]
brief: [github-actions]
reward: true
categories: github-actions
keywords: hexo,github,github-actions
cover: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039789.jpg
image: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039790.jpg
---


## 仓库准备


项目仓库 | 说明
---|---
https://github.com/WinterChenS/blog-back | 用于存放 hexo 生成的项目，可以理解成源码
https://github.com/WinterChenS/WinterChenS.github.io | 存放 hexo 编译后的静态文件，也是博客页面

## 秘钥生成

Hexo编译之后需要把生成的静态页面代码push到github pages的仓库，也就是 `WinterChenS/WinterChenS.github.io` ，没有秘钥就没有权限push。

> 随便找一台电脑或者服务器，生成秘钥：

```
ssh-keygen -f github-deploy-key # 三次回车即可
```

以上步骤会生成`github-deploy-key` 和 `github-deploy-key.pub` 两个文件。

## 配置github仓库

### 配置blog-back仓库

打开 `https://github.com/WinterChenS/blog-back/settings/secrets` 点击 `Add new secrets`，分别在:

- Name 输入 `HEXO_DEPLOY_KEY`
- Value 输入前面生成的私有KEY `github-deploy-key` 的内容

### 配置WinterChenS.github.io仓库

打开 https://github.com/WinterChenS/WinterChenS.github.io/settings/Deploy keys，点击 Add deploy key，分别在:

- Title 输入 `HEXO_DEPLOY_KEY`
- Key 输入前面生成的公KEY `github-deploy-key.pub` 的内容名称随意，但要勾选 Allow write access

## 编写 Action 脚本

使用前先要申请，直接打开`https://github.com/WinterChenS/WinterChenS.github.io/actions/new`

main.yml

```
name: Deploy Blog

on: [push] # 当有新push时运行

env:
  TZ: Asia/Shanghai

jobs:
  build: # 一项叫做build的任务

    runs-on: ubuntu-latest # 在最新版的Ubuntu系统下运行
    
    steps:
    - name: Checkout # 将仓库内master分支的内容下载到工作目录
      uses: actions/checkout@v1 # 脚本来自 https://github.com/actions/checkout
      
    - name: Use Node.js 10.x # 配置Node环境
      uses: actions/setup-node@v1 # 配置脚本来自 https://github.com/actions/setup-node
      with:
        node-version: "10.x"
    
    - name: Setup Hexo env
      env:
        ACTION_DEPLOY_KEY: ${{ secrets.HEXO_DEPLOY_KEY }} # 这里是上面WinterChenS.github.io新增的公钥：HEXO_DEPLOY_KEY
      run: |
        # set up private key for deploy
        mkdir -p ~/.ssh/
        echo "$ACTION_DEPLOY_KEY" | tr -d '\r' > ~/.ssh/id_rsa # 配置秘钥
        chmod 600 ~/.ssh/id_rsa
        ssh-keyscan github.com >> ~/.ssh/known_hosts
        # set git infomation
        git config --global user.name 'winterchens' # 换成你自己的邮箱和名字
        git config --global user.email '1085143002@qq.com'
        # install dependencies
        npm i -g hexo-cli # 安装hexo
        npm i
        # 拉取主题代码
        rm -rf themes/*
        git clone https://github.com/WinterChenS/hexo-theme-diaspora.git themes/diaspora
        
  
    - name: Deploy
      run: |
        # publish
        hexo generate && hexo deploy # 执行部署程序
        
```

## 修改blog-back根目录的_config.yml
如果你使用的是http，那么需要修改为ssh，已经是ssh就无须修改
```
deploy:
  type: git
  repo: git@github.com:WinterChenS/WinterChenS.github.io.git
  branch: master
```

以后只需要把代码提交到blog-back就可以自动进行编译发布了，是不是很爽

