---
layout: post
title: 站点托管CDN加速的平台vercel使用之组织免费使用
date: 2020-08-28 17:29
comments: true
tags: [share]
brief: [share]
reward: true
categories: github
keywords: github
cover: http://img.winterchen.com/20200823161149.jpg
image: http://img.winterchen.com/20200823161149.jpg
---

> vercel是什么？

### 简介

vercel是一个站点托管平台，提供CDN加速，同类的平台有Netlify 和 Github Pages，相比之下，vercel国内的访问速度更快，并且提供Production环境和development环境，对于项目开发非常的有用的，并且支持持续集成，一次push或者一次PR会自动化构建发布，发布在development环境，都会生成不一样的链接可供预览。

但是vercel只是针对个人用户免费，teams是收费的，对于Organization用户来说成本还是挺高的，那么如果在Organization Project在vercel中免费呢？

### 方案

我们可以选择绕过vercel的产品定位策略，vercel提供了CLI生成个人项目，那么我们可以利用github action部署到vercel，下面来讲讲具体的实现方案：

1.用户将代码push到github；
2.触发github action构建，使用vercel的action将当前代码库的文件推送到vercel；
3.vercel进行构建部署；


### 步骤

#### 创建一个项目

如果已经存在仓库，clone该仓库到安装过nodejs的电脑，不存在仓库新建一个项目并且push到github。

#### 安装vercel cli

```
npm i -g vercel
```

#### 部署项目

因为vercel不支持网页端创建项目，只支持CLI创建项目，所以我们这一步的目的就是创建项目，后续的构建和发布直接使用github action 持续集成部署。

进入项目根目录执行

```
vercel

```
按照需求进行配置相关信息即可创建项目，最重要的是project.json内的项目相关信息



会打印出创建的项目相关的信息，orgid 和 projectid （非常重要的参数）

#### 获取相关配置

##### github

[获取Github Access Token](https://github.com/settings/tokens)

##### vercel

项目根目录运行

```
cat .vercel/project.json
```

```
{"orgId":"r359XAnYONVAmiXtdxZ22A2E","projectId":"Qma3GdwoiAfJSsbsSydBgaCDh8LJj6wTWvvqpUwrN6J2F3"}
```

1. Org ID：标示用户的Id，对应project.json中的orgId

2. Project ID：项目的标示，对应project.json中的projectId

3. Vercel Token： [点击Create](https://vercel.com/account/tokens)

##### 配置github Secret

github action可以获取Secret参数，一些敏感信息可以设置到Secret中，并且以变量的方式传入到github action的参数中。

打开github项目的Setting -> Secret，点击 new secret创建三个配置

- VERCEL_TOKEN：上一步的Vercel Token
- ORG_ID：  上一步的Org ID
- PROJECT_ID：上一步的Project ID

配置好这些参数就可以进行github action脚本的编写了

#### 编写Github Action脚本

在github中创建action（具体方法自行搜索）

使用了`amondnet/vercel-action@v19.0.1+3` 组件

```
- name: Vercel Action
      # You may pin to the exact commit or the version.
      # uses: amondnet/vercel-action@77cb0ce3642a451f7f18d63821c0e26f7adead9a
      uses: amondnet/vercel-action@v19.0.1+3
      with:
        # Vercel token
        vercel-token: ${{ secrets.VERCEL_TOKEN }}
        # 
        # if you want to comment on pr and commit, set token
        github-token: ${{ secrets.OP_TOKEN }} # optional
        # if you want to create github deployment, set true, default: false
        github-deployment: false # optional, default is false
        # the working directory
        working-directory: ./ # optional
        # Vercel CLI 17+, ❗️  The `name` property in vercel.json is deprecated (https://zeit.ink/5F)
        vercel-project-id: ${{ secrets.PROJECT_ID}} # optional
        # Vercel CLI 17+, ❗️  The `name` property in vercel.json is deprecated (https://zeit.ink/5F)
        vercel-org-id: ${{ secrets.ORG_ID}} # optional
        vercel-args: '--prod' #这是一个关键点，这里执行生产生产环境还是开发环境，默认是测试环境
```

#### 案例

完整的案例：[https://github.com/sam-bo/blog_back](https://github.com/sam-bo/blog_back)

案例里面的其它脚本可以忽略，根据实际的情况进行编写。


#### 总结

安装上面的步骤，代码提交之后就可以自动构建了，是不是很简单呢？

vercel在国内的访问速度可以秒杀github pages了，vercel虽然不支持组织，利用这种方式我们可以免费使用。



