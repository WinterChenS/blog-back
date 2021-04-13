---
layout: post
title: Java使用mpxj导入.mpp格式的Project文件（甘特图）
date:  2018-01-18 22:00
comments: true
tags: [java]
brief: "java 读取 mpp文件"
reward: true
categories: java
keywords: java
cover: https://gitee.com/winter_chen/img/raw/master/blog/20210413121548.jpeg
image: https://gitee.com/winter_chen/img/raw/master/blog/20210413121548.jpeg
---

> 最近换工作了，主要的项目都是企业内部为支撑的管理平台，刚入入职没多久，遇到了一个需求，就是导入微软的Project文件，踩过不少坑，所以记录一下，后续还有从数据库导出Project引导文件，也就是xml文件
<!--  more  -->

![这里写图片描述](http://img.blog.csdn.net/20180117180051197?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvV2ludGVyX2NoZW4wMDE=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)




## 依赖
```
<!-- 读取project文件 -->
<dependency>
	<groupId>net.sf.mpxj</groupId>
	<artifactId>mpxj</artifactId>
	<version>7.1.0</version>
</dependency>
```
## 代码

 博主使用的读取方式是递归读取的，无论Project文件中的任务有多少层，都可以读到，好了，直接看代码，注意看注释：
 

### 核心方法

```java

 @Transactional
    @Override
    public void readMmpFileToDB(File file) {//如果读取的是MultipartFile，那么直接使用获取InputStream即可
        try{
        	//这个是读取文件的组件
            MPPReader mppRead = new MPPReader();
            //注意，如果在这一步出现了读取异常，肯定是版本不兼容，换个版本试试
            ProjectFile pf = mppRead.read(file);
            //从文件中获取的任务对象
            List<Task> tasks = pf.getChildTasks();
            //这个可以不用，这个list只是我用来装下所有的数据，如果不需要可以不使用
            List<Project> proList = new LinkedList<>();
            //这个是用来封装任务的对象，为了便于区别，初始化批次号，然后所有读取的数据都需要加上批次号
            Project pro = new Project();
            pro.setBatchNum(StringUtils.UUID());//生成批次号UUID
            //这个方法是一个递归方法
            getChildrenTask(tasks.get(0), pro ,proList, 0);
        }catch (MPXJException e) {
            logger.error(e.getMessage());
            throw new RuntimeException();
        } catch (Exception e) {
            logger.error(e.getMessage());
            throw new RuntimeException();
        }
    }
```
```java
 /**
 * 这个方法是一个递归
 * 方法的原理：进行读取父任务，如果下一层任务还是父任务，那么继续调用当前方法，如果到了最后一层，调用另外一个读取底层的方法
 * @param task
 * @param project
 * @param list
 * @param levelNum
 */
public void getChildrenTask(Task task, Project project, List<Project> list, int levelNum){
        if(task.getResourceAssignments().size() == 0){//这个判断是进行是否是最后一层任务的判断==0说明是父任务
            levelNum ++;//层级号需要增加，这个只是博主用来记录该层的层级数
            List<Task> tasks = task.getChildTasks();//继续获取子任务
            for (int i = 0; i < tasks.size(); i++) {//该循环是遍历所有的子任务
                if(tasks.get(i).getResourceAssignments().size() == 0){//说明还是在父任务层
                    Project pro = new Project();
                    if (project.getProjId() != null){//说明不是第一次读取了，因为如果是第一层，那么还没有进行数据库的添加，没有返回主键Id
                        pro.setParentId(project.getProjId());//将上一级目录的Id赋值给下一级的ParentId
                    }
                    pro.setBatchNum(project.getBatchNum());//批量号
                    pro.setImportTime(new Date());//导入时间
                    pro.setLevel(levelNum);//层级
                    pro.setTaskName(tasks.get(i).getName());//这个是获取文件中的“任务名称”列的数据
                    pro.setDurationDate(tasks.get(i).getDuration().toString());//获取的是文件中的“工期”
                    pro.setStartDate(tasks.get(i).getStart());//获取文件中的 “开始时间”
                    pro.setEndDate(tasks.get(i).getFinish());//获取文件中的 “完成时间”
                    pro.setResource(tasks.get(i).getResourceGroup());//获取文件中的 “资源名称”
                    this.addProjectInfo(pro);//将该条数据添加到数据库，并且会返回主键Id，用做子任务的ParentId,这个需要在mybatis的Mapper中设置
                    getChildrenTask(tasks.get(i), pro,list,levelNum);//继续进行递归，当前保存的只是父任务的信息
                }else{//继续进行递归
                    getChildrenTask(tasks.get(i), project, list, levelNum);
                }
            }
        }else{//说明已经到了最底层的子任务了，那么就调用进行最底层数据读取的方法
            if (project.getProjId() != null){
                getResourceAssignment(task, project, list, levelNum);
            }
        }
    }
```

```java

public void getResourceAssignment(Task task, Project project, List<Project> proList, int levelNum){
    List<ResourceAssignment> list = task.getResourceAssignments();//读取最底层的属性
    ResourceAssignment rs = list.get(0);
    Project pro = new Project();
    pro.setTaskName(task.getName());
    pro.setParentId(project.getProjId());
    pro.setLevel(levelNum);
    pro.setImportTime(new Date());
    pro.setBatchNum(project.getBatchNum());
    pro.setDurationDate(task.getDuration().toString());
    pro.setStartDate(rs.getStart());//注意，这个从ResourceAssignment中读取
    pro.setEndDate(rs.getFinish());//同上
    String resource = "";
    if(list.size() > 1){
        for (int i = 0; i < list.size(); i++) {
            if (list.get(i).getResource() != null){
                if(i < list.size() - 1){
                    resource += list.get(i).getResource().getName() + ",";
                }else{
                    resource += list.get(i).getResource().getName();
                }
            }
        }
    }else{

        if(list.size() > 0 && list.get(0).getResource() != null){
            resource = list.get(0).getResource().getName();
        }
    }
    if(!StringUtils.isEmpty(resource)){
        pro.setResource(resource);
    }
    this.addProjectInfo(pro);//将数据保存在数据库中,同样会返回主键
    proList.add(pro);

}
```


### 封装对象

```java

package com.winter.model;

import java.util.Date;

/**
 * Project文件封装类
 * Created By Donghua.Chen on  2018/1/9
 */
public class Project {
    /* 自增主键Id */
    private Integer projId;
    /* 上级Id */
    private Integer parentId;
    /* 结构层级 */
    private Integer level;
    /* 任务名称 */
    private String taskName;
    /* 工期 */
    private String durationDate;
    /* 开始时间 */
    private Date startDate;
    /* 结束时间 */
    private Date endDate;
    /* 前置任务ID */
    private Integer preTask;
    /* 资源名称 */
    private String resource;
    /* 导入时间 */
    private Date importTime;
    /* 批次号 */
    private String batchNum;

    //省略get、set方法

```

### Mybatis 接口方法

```java
/**
     * 插入project数据
     * @param project
     * @return
     */
    int addProjectSelective(Project project);

```

### Mapper
```xml
<sql id="TABLE_PROJECT">
  PROJECT
</sql>

<!-- 插入数据之后返回主键 需要这两个配置： useGeneratedKeys="true" keyProperty="projId" -->
<insert id="addProjectSelective" useGeneratedKeys="true" keyProperty="projId" parameterType="com.winter.model.Project">
    INSERT INTO
    <include refid="TABLE_PROJECT"/>
    <trim prefix="(" suffix=")" suffixOverrides="," >
        <if test="parentId != null">
            parentId,
        </if>
        <if test="level != null">
            level,
        </if>
        <if test="taskName != null">
            taskName,
        </if>
        <if test="durationDate != null">
            durationDate,
        </if>
        <if test="startDate != null">
            startDate,
        </if>
        <if test="endDate != null">
            endDate,
        </if>
        <if test="preTask != null">
            preTask,
        </if>
        <if test="resource != null">
            resource,
        </if>
        <if test="importTime != null">
            importTime,
        </if>
        <if test="importTime != null">
            batchNum,
        </if>
    </trim>
    <trim prefix="values (" suffix=")" suffixOverrides="," >
        <if test="parentId != null">
            #{parentId, jdbcType=INTEGER},
        </if>
        <if test="level != null">
            #{level, jdbcType=INTEGER},
        </if>
        <if test="taskName != null">
            #{taskName, jdbcType=VARCHAR},
        </if>
        <if test="durationDate != null">
            #{durationDate, jdbcType=VARCHAR},
        </if>
        <if test="startDate != null">
            #{startDate, jdbcType=DATE},
        </if>
        <if test="endDate != null">
            #{endDate, jdbcType=DATE},
        </if>
        <if test="preTask != null">
            #{preTask, jdbcType=INTEGER},
        </if>
        <if test="resource != null">
            #{resource, jdbcType=VARCHAR},
        </if>
        <if test="importTime != null">
            #{importTime, jdbcType=DATE},
        </if>
        <if test="batchNum != null">
            #{batchNum, jdbcType=VARCHAR},
        </if>
    </trim>
</insert>


```

## 效果
![这里写图片描述](http://img.blog.csdn.net/20180117180307631?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvV2ludGVyX2NoZW4wMDE=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)


## 拓展
当然，还有很多自定义的字段读取，如果有需要可以联系我，或者看官方文档
email：1085143002@qq.com



## 相关资源

* mpxj官方API文档：http://www.mpxj.org/apidocs/index.html
* 项目源码：https://github.com/WinterChenS/springboot-mybatis-demo
* 导入模板在源码的file文件夹中，sql在sql文件夹中




