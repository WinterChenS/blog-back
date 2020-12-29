---
layout: post
title: springboot集成Oozie实战
date: 2020-12-01 19:43
comments: true
tags: [hadoop, oozie, springboot]
brief: [share]
reward: true
categories: hadoop
keywords: hadoop, oozie, springboot
cover: http://img.winterchen.com/20201201195903.jpg
image: http://img.winterchen.com/20201201195903.jpg
---

![](http://img.winterchen.com/20201201195903.jpg)


本文将以springboot调用Oozie的API实现workflow和coordinator等任务的提交停止

## 前提：

关于hadoop的集成，请参考另外一篇文章，这里就过多的赘述：

[springboot集成hadoop实战](https://blog.winterchen.com/2020/12/01/2020-12-01-springboot-hadoop-hdfs-mapreduce/)

## maven坐标

```xml
			<dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-common</artifactId>
            <version>${hadoop.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-streaming</artifactId>
            <version>${hadoop.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-yarn-common</artifactId>
            <version>${hadoop.version}</version>
            <exclusions>
                <exclusion>
                    <groupId>com.google.guava</groupId>
                    <artifactId>guava</artifactId>
                </exclusion>
            </exclusions>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-distcp</artifactId>
            <version>${hadoop.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-mapreduce-client-core</artifactId>
            <version>${hadoop.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-hdfs</artifactId>
            <version>${hadoop.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-mapreduce-client-jobclient</artifactId>
            <version>${hadoop.version}</version>
            <scope>provided</scope>
        </dependency>

				<!-- oozie -->
        <dependency>
            <groupId>org.apache.oozie</groupId>
            <artifactId>oozie-client</artifactId>
            <version>4.3.0</version>
        </dependency>
```

## 配置

```yaml
hdfs:
  hdfsPath: hdfs://bigdata-master:8020
  hdfsName: bigdata-master

oozie:
  url: http://bigdata-master:11000/oozie
  wf:
    application:
      path: hdfs://bigdata-master:9000/user/oozie/workflow/hiveserver2.xml
  use:
    system:
      libpath: true
  libpath: hdfs://bigdata-master:8020/user/oozie/share/lib
  callback:
    url: http://172.16.120.29:8080/label/oozie/callback?executeType=$1\&taskType=$2\&callbackId=$3
  jdbc:
    url: jdbc:hive2://192.168.150.119:10000/default
    password:
  nameNode: hdfs://bigdata-master:8020
  resourceManager: hdfs://bigdata-master:8088
  queueName: default
  job-tracker: bigdata-master:8032
```

```java
package com.winterchen.hadoopdemo.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * @author winterchen
 * @version 1.0
 * @date 2020/11/19 7:21 下午
 * @description
 **/
@Data
@AllArgsConstructor
@NoArgsConstructor
@Component
public class OozieConfig {

    @Value("${oozie.nameNode}")
    private String nameNode;

    @Value("${oozie.job-tracker}")
    private String jobTracker;

    @Value("${oozie.resourceManager}")
    private String resourceManager;

    @Value("${oozie.queueName}")
    private String queueName;

    @Value("${oozie.url}")
    private String url;

    @Value("${oozie.wf.application.path}")
    private String oozieApplicationPath;

    @Value("${oozie.libpath}")
    private String oozieLibPath;

    @Value("${oozie.use.system.libpath}")
    private boolean oozieSystemLibPath;

    @Value("${oozie.jdbc.url}")
    private String jdbcUrl;

    @Value("${oozie.jdbc.password}")
    private String password;

    @Value("${oozie.callback.url}")
    private String callbackUrl;

}
```

## 基础类

```java
/**
 * @author winterchen
 * @version 1.0
 * @date 2020/11/23 2:23 下午
 * @description
 **/
public class OozieConstants {

    public static final String NAME_NODE= "nameNode";
    public static final String RESOURCE_MANAGER = "resourcemanager";
    public static final String QUEUE_NAME = "queueName";
    public static final String ROOT_DIR = "rootdir";
    public static final String JOB_TRACKER = "jobTracker";
    public static final String JOB_OUTPUT = "jobOutput";
    public static final String JDBC_URL = "jdbcUrl";
    public static final String PASSWORD = "password";
    public static final String SQL_INPUT = "sqlInput";
    public static final String USER_NAME = "user.name";
    public static final String TASK_TYPE = "taskType";
    public static final String SHELL_FILE_NAME = "shellFileName";
    public static final String SHELL_FILE_PATH = "shellFilePath";
    public static final String CALLBACK_ID = "callbackId";
    public static final String WORKFLOW_ROOT = "workflowRoot";
    public static final String START = "start";
    public static final String END = "end";

}
```

```java
package com.winterchen.hadoopdemo.model;

import com.winterchen.hadoopdemo.enums.FrequencyTypeEnum;
import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.*;

/**
 * @author winterchen
 * @version 1.0
 * @date 2020/11/25 6:01 下午
 * @description 定时调度任务请求
 **/
@Data
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = false)
@ToString
@Builder
@ApiModel
public class CoordinatorRequest {

    @ApiModelProperty("定时调度任务名称")
    private String coordName;
    @ApiModelProperty("定时调度任务文件路径")
    private String coordPath;
    @ApiModelProperty("频率")
    private FrequencyTypeEnum frequencyType;
    @ApiModelProperty("开始时间")
    private String startTime;
    @ApiModelProperty("结束时间")
    private String endTime;
    @ApiModelProperty("workflow名称")
    private String wfName;
    @ApiModelProperty("workflow路径")
    private String wfPath;
    @ApiModelProperty("回调编号")
    private String callbackId;

}
```

```java
package com.winterchen.hadoopdemo.model;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.*;

/**
 * @author winterchen
 * @version 1.0
 * @date 2020/11/25 5:33 下午
 * @description workflow任务请求
 **/
@Data
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = false)
@ToString
@Builder
@ApiModel
public class WorkflowRequest {

    @ApiModelProperty("workflow名称")
    private String wfName;
    @ApiModelProperty("workflow路径")
    private String wfPath;
    @ApiModelProperty("执行的sql")
    private String sql;
    @ApiModelProperty("回调编号")
    private String callbackId;

}
```

## 功能实现

```java
package com.winterchen.hadoopdemo.service;

import com.winterchen.hadoopdemo.enums.FrequencyTypeEnum;
import com.winterchen.hadoopdemo.model.CoordinatorRequest;
import com.winterchen.hadoopdemo.model.WorkflowRequest;

/**
 * @author winterchen
 * @version 1.0
 * @date 2020/11/23 2:06 下午
 * @description
 **/
public interface OozieService {

    /**
     * @Author winterchen
     * @Description 提交workflow任务
     * @Date 6:21 下午 2020/11/25
     * @Param [workflowRequest]
     * @return java.lang.String
     **/
    String submitWorkflow(WorkflowRequest workflowRequest);

    /**
     * @Author winterchen
     * @Description 提交coordinator任务
     * @Date 6:21 下午 2020/11/25
     * @Param [coordinatorRequest]
     * @return java.lang.String
     **/
    String submitCoordinator(CoordinatorRequest coordinatorRequest);

    /**
     * @Author winterchen
     * @Description 创建并上传sql文件至hdfs
     * @Date 6:21 下午 2020/11/25
     * @Param [sql, sqlPath]
     * @return java.lang.String 文件地址
     **/
    String createSqlFileAndUpload(String sql, String sqlPath);

    /**
     * @Author winterchen
     * @Description 创建并上传workflow任务脚本文件至hdfs
     * @Date 6:22 下午 2020/11/25
     * @Param [wfName, wfPath, sqlPath, callbackId]
     * @return String 文件地址
     **/
    String createWfFileAndUpload(String wfName, String wfPath, String sqlPath, String callbackId);

    /**
     * @Author winterchen
     * @Description 创建并上传coordinator定时任务脚本文件至hdfs
     * @Date 6:23 下午 2020/11/25
     * @Param [coordName, coordPath, wfPath, frequencyType, callbackId]
     * @return String 文件地址
     **/
    String createCoordFileAndUpload(String coordName, String coordPath, String wfPath, FrequencyTypeEnum frequencyType, String callbackId);

    /**
     * @Author winterchen
     * @Description 创建shell脚本并上传
     * @Date 6:41 下午 2020/11/25
     * @Param [shellFileName, shellFilePath]
     * @return String 文件地址
     **/
    String  createShellFileAndUpload(String shellFileName, String shellFilePath);

    /**
     * @Author winterchen
     * @Description 处理回调
     * @Date 6:24 下午 2020/11/25
     * @Param [targetType, targetId]
     * @return void
     **/
    void executeCallback(String executeType, String taskType, String callbackId);

    /**
     * @Author winterchen
     * @Description 停止定时调度任务
     * @Date 6:24 下午 2020/11/25
     * @Param [jobId]
     * @return void
     **/
    void killCoordinatorJob(String jobId);

}
```

```java
package com.winterchen.hadoopdemo.service.impl;

import cn.hutool.core.date.DateUtil;
import com.winterchen.hadoopdemo.constants.OozieConstants;
import com.winterchen.hadoopdemo.enums.FrequencyTypeEnum;
import com.winterchen.hadoopdemo.enums.TaskTypeEnum;
import com.winterchen.hadoopdemo.model.CoordinatorRequest;
import com.winterchen.hadoopdemo.model.OozieConfig;
import com.winterchen.hadoopdemo.model.WorkflowRequest;
import com.winterchen.hadoopdemo.service.OozieService;
import lombok.extern.slf4j.Slf4j;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.oozie.client.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.util.Properties;

/**
 * @author winterchen
 * @version 1.0
 * @date 2020/11/23 2:06 下午
 * @description
 **/
@Slf4j
@Service
public class OozieServiceImpl implements OozieService {

    @Autowired
    private FileSystem fileSystem;

    private final OozieConfig oozieConfig;

    @Autowired
    public OozieServiceImpl(OozieConfig oozieConfig) {
        this.oozieConfig = oozieConfig;
    }

    @Override
    public String submitWorkflow(WorkflowRequest workflowRequest) {
        try {
            OozieClient oozieClient = new OozieClient(oozieConfig.getUrl());
            oozieClient.setDebugMode(1);
            Path appPath = new Path(fileSystem.getHomeDirectory(), workflowRequest.getWfPath().concat(workflowRequest.getWfName()).concat(".xml"));
            // 创建相关文件

            // 创建并上传sql文件
            String sqlPath = workflowRequest.getWfPath().concat("sql/".concat(workflowRequest.getWfName()).concat("-sql.q"));
            createSqlFileAndUpload(workflowRequest.getSql(), sqlPath);

            // 创建shell脚本
            String shellFileName = workflowRequest.getWfName() + "-shell.sh";
            String shellFilePath = workflowRequest.getWfPath().concat(workflowRequest.getWfName()).concat("/shell/");
            String shellPath = createShellFileAndUpload(shellFileName, shellFilePath);

            // 创建并上传wf脚本文件
            createWfFileAndUpload(workflowRequest.getWfName(), workflowRequest.getWfPath(), sqlPath, workflowRequest.getCallbackId());

            // 创建脚本任务的配置
            Properties prop = oozieClient.createConfiguration();
            prop.setProperty(OozieClient.APP_PATH, appPath.toString());
            prop.setProperty(oozieClient.LIBPATH, oozieConfig.getOozieLibPath());
            prop.setProperty(oozieClient.USE_SYSTEM_LIBPATH, String.valueOf(oozieConfig.isOozieSystemLibPath()));

            /*Set Your Application Configuration*/
            prop.setProperty(OozieConstants.NAME_NODE, oozieConfig.getNameNode());
            prop.setProperty(OozieConstants.JOB_TRACKER,oozieConfig.getJobTracker());
            Path outputPath = new Path(fileSystem.getHomeDirectory(), workflowRequest.getWfPath().concat("output/"));
            prop.setProperty(OozieConstants.JOB_OUTPUT, outputPath.toString());
            prop.setProperty(OozieConstants.JDBC_URL, oozieConfig.getJdbcUrl());
            prop.setProperty(OozieConstants.PASSWORD, StringUtils.isEmpty(oozieConfig.getPassword()) ? "" : oozieConfig.getPassword());
            prop.setProperty(OozieConstants.SQL_INPUT,workflowRequest.getWfPath().concat("sql/"));
            prop.setProperty(OozieConstants.USER_NAME,"admin");
            prop.setProperty(OozieConstants.TASK_TYPE, TaskTypeEnum.WORKFLOW.name());
            prop.setProperty(OozieConstants.SHELL_FILE_NAME,shellFileName);
            prop.setProperty(OozieConstants.SHELL_FILE_PATH, shellPath);
            prop.setProperty(OozieConstants.CALLBACK_ID, workflowRequest.getCallbackId());
            prop.setProperty(OozieConstants.QUEUE_NAME, oozieConfig.getQueueName());

            String jobId = oozieClient.submit(prop);
            oozieClient.start(jobId);

            log.debug("workflow job submitted, jobId = {}", jobId);

            return jobId;
        } catch (OozieClientException e) {
            log.error("workflow任务提交失败" ,e);
        }

        return null;
    }

    @Override
    public String submitCoordinator(CoordinatorRequest coordinatorRequest) {

        try {
            OozieClient oozieClient = new OozieClient(oozieConfig.getUrl());
            oozieClient.setDebugMode(1);
            Path rootPath = new Path(fileSystem.getHomeDirectory(), coordinatorRequest.getCoordPath());
            Path appPath = new Path(fileSystem.getHomeDirectory(), coordinatorRequest.getCoordPath()
                    .concat(coordinatorRequest.getCoordName()).concat(".xml"));
            Path wf = new Path(fileSystem.getHomeDirectory(), coordinatorRequest.getWfPath());
            // 创建相关文件
            // 创建并上传定时调度任务脚本
            createCoordFileAndUpload(coordinatorRequest.getCoordName(),coordinatorRequest.getCoordPath(),
                    wf.toString().concat("/").concat(coordinatorRequest.getWfName()).concat(".xml"),coordinatorRequest.getFrequencyType(), coordinatorRequest.getCallbackId());

            // 创建shell脚本
            String shellFileName = coordinatorRequest.getWfName() + "-shell.sh";
            String shellFilePath = coordinatorRequest.getWfPath().concat(coordinatorRequest.getWfName()).concat("/shell/");
            String shellPath = createShellFileAndUpload(shellFileName, shellFilePath);

            // 创建脚本任务的配置
            Properties prop = oozieClient.createConfiguration();
            prop.setProperty(OozieClient.COORDINATOR_APP_PATH, appPath.toString());
            prop.setProperty(oozieClient.LIBPATH, oozieConfig.getOozieLibPath());
            prop.setProperty(oozieClient.USE_SYSTEM_LIBPATH, String.valueOf(oozieConfig.isOozieSystemLibPath()));
            prop.setProperty(OozieConstants.JOB_TRACKER,oozieConfig.getJobTracker());
            prop.setProperty(OozieConstants.USER_NAME,"admin");
            prop.setProperty(OozieConstants.WORKFLOW_ROOT, rootPath.toString());
            String start = DateUtil.format(DateUtil.parse(coordinatorRequest.getStartTime(), "yyyy-MM-dd HH:mm:ss"), "yyyy-MM-dd'T'HH:mm'Z'");
            prop.setProperty(OozieConstants.START, start);
            String end = DateUtil.format(DateUtil.parse(coordinatorRequest.getEndTime(), "yyyy-MM-dd HH:mm:ss"), "yyyy-MM-dd'T'HH:mm'Z'");
            prop.setProperty(OozieConstants.END, end);
            Path outputPath = new Path(fileSystem.getHomeDirectory(), coordinatorRequest.getWfPath().concat("output/"));
            prop.setProperty(OozieConstants.JOB_OUTPUT, outputPath.toString());
            prop.setProperty(OozieConstants.JDBC_URL, oozieConfig.getJdbcUrl());
            prop.setProperty(OozieConstants.PASSWORD, StringUtils.isEmpty(oozieConfig.getPassword()) ? "" : oozieConfig.getPassword());
            prop.setProperty(OozieConstants.SQL_INPUT,coordinatorRequest.getWfPath().concat("sql/"));
            prop.setProperty(OozieConstants.TASK_TYPE, TaskTypeEnum.COORDINATOR.name());
            prop.setProperty(OozieConstants.SHELL_FILE_NAME,shellFileName);
            prop.setProperty(OozieConstants.SHELL_FILE_PATH, shellPath);
            prop.setProperty(OozieConstants.CALLBACK_ID, coordinatorRequest.getCallbackId());
            prop.setProperty(OozieConstants.QUEUE_NAME, oozieConfig.getQueueName());

            /*Set Your Application Configuration*/
            prop.setProperty(OozieConstants.NAME_NODE, oozieConfig.getNameNode());

            String jobId = oozieClient.submit(prop);

            log.debug("workflow job submitted, jobId = {}", jobId);

            return jobId;
        } catch (OozieClientException e) {
            log.error("workflow任务提交失败" ,e);
        }

        return null;
    }

    @Override
    public String createSqlFileAndUpload(String sql, String sqlPath) {
        Writer writer = null;
        try {
            Path sqlP = new Path(fileSystem.getHomeDirectory(),sqlPath);
            writer = new OutputStreamWriter(fileSystem.create(sqlP));

            writer.write(sql);
            return sqlP.toString();
        } catch (IOException e) {
            log.error("创建sql文件失败", e);
        } finally {
            if (null != writer) {
                try {
                    writer.close();
                } catch (IOException e) {
                    log.error("关闭流失败", e);
                }
            }
        }
        return null;
    }

    @Override
    public String createWfFileAndUpload(String wfName, String wfPath, String sqlFileName, String callbackId) {
        Writer writer = null;
        try {
            Path wf = new Path(fileSystem.getHomeDirectory(),wfPath.concat(wfName).concat(".xml"));
            writer = new OutputStreamWriter(fileSystem.create(wf));
            String wfApp =
                    "<workflow-app xmlns='uri:oozie:workflow:0.4' name='" + wfName + "'>\n" +
                            "    <start to='my-hive2-action'/>\n" +
                            "    <action name='my-hive2-action'>\n" +
                            "       <hive2 xmlns='uri:oozie:hive2-action:0.1'>\n" +
                            "           <name-node>${nameNode}</name-node>\n" +
                            "           <prepare>\n" +
                            "               <delete path='${jobOutput}'/>\n" +
                            "           </prepare>\n" +
                            "           <configuration>\n" +
                            "                <property>\n" +
                            "                    <name>mapred.compress.map.output</name>\n" +
                            "                    <value>true</value>\n" +
                            "                </property>\n" +
                            "           </configuration>\n" +
                            "           <jdbc-url>${jdbcUrl}</jdbc-url>\n" +
//                            "           <password>${password}</password>\n" +
                            "           <script>" + sqlFileName + "</script>\n" +
                            "           <param>InputDir=${sqlInput}</param>\n" +
                            "           <param>OutputDir=${jobOutput}</param>\n" +
                            "       </hive2>\n" +
                            "    <ok to='success-action'/>\n" +
                            "    <error to='error-action'/>\n" +
                            "    </action>\n" +
                            "    <!-- 成功回调 -->\n" +
                            "    <action name='success-action'>\n" +
                            "        <shell xmlns=\"uri:oozie:shell-action:0.2\">\n" +
                            "            <job-tracker>${jobTracker}</job-tracker>\n" +
                            "            <name-node>${nameNode}</name-node>\n" +
                            "            <configuration>\n" +
                            "                <property>\n" +
                            "                  <name>mapred.job.queue.name</name>\n" +
                            "                  <value>${queueName}</value>\n" +
                            "                </property>\n" +
                            "            </configuration>\n" +
                            "            <exec>${shellFileName}</exec>\n" +
                            "            <argument>${taskType}</argument>\n" +
                            "            <argument>OK</argument>\n" +
                            "            <argument>${callbackId}</argument>\n" +
                            "            <file>${shellFilePath}#${shellFilePath}</file> <!--Copy the executable to compute node's current working directory -->\n" +
                            "        </shell>\n" +
                            "        <ok to='end' />\n" +
                            "        <error to='fail' />\n" +
                            "    </action>\n" +
                            "     \n" +
                            "    <!-- 失败回调 -->\n" +
                            "    <action name='error-action'>\n" +
                            "        <shell xmlns=\"uri:oozie:shell-action:0.2\">\n" +
                            "            <job-tracker>${jobTracker}</job-tracker>\n" +
                            "            <name-node>${nameNode}</name-node>\n" +
                            "            <configuration>\n" +
                            "                <property>\n" +
                            "                  <name>mapred.job.queue.name</name>\n" +
                            "                  <value>${queueName}</value>\n" +
                            "                </property>\n" +
                            "            </configuration>\n" +
                            "            <exec>${shellFileName}</exec>\n" +
                            "            <argument>${taskType}</argument>\n" +
                            "            <argument>FAIL</argument>\n" +
                            "            <argument>${callbackId}</argument>\n" +
                            "            <file>${shellFilePath}#${shellFilePath}</file> <!--Copy the executable to compute node's current working directory -->\n" +
                            "        </shell>\n" +
                            "        <ok to='end' />\n" +
                            "        <error to='fail' />\n" +
                            "    </action>\n" +
                            "    <kill name='fail'>\n" +
                            "        <message>执行脚本失败</message>\n" +
                            "    </kill>\n" +
                            "    <end name='end'/>\n"   +
                            "</workflow-app>";
            writer.write(wfApp);
            return wf.toString();
        } catch (IOException e) {
            log.error("创建workflow文件失败", e);
        } finally {
            if (null != writer) {
                try {
                    writer.close();
                } catch (IOException e) {
                    log.error("关闭流失败", e);
                }
            }
        }
        return null;
    }

    @Override
    public String createCoordFileAndUpload(String coordName, String coordPath, String wfPath, FrequencyTypeEnum frequencyType, String callbackId) {
        Writer writer = null;
        try {
            Path coord = new Path(fileSystem.getHomeDirectory(),coordPath.concat(coordName).concat(".xml"));
            writer = new OutputStreamWriter(fileSystem.create(coord));
            String frequency = FrequencyTypeEnum.getExpressionByName(frequencyType.name(), 1);
            String wfApp =
                    "<coordinator-app name='" + coordName + "' frequency='" + frequency + "' start='${start}' end='${end}' timezone='Asia/Shanghai'\n" +
                            "                 xmlns='uri:oozie:coordinator:0.4'>\n" +
                            "        <action>\n" +
                            "        <workflow>\n" +
                            "            <app-path>" + wfPath + "</app-path>\n" +
                            "        </workflow>\n" +
                            "    </action>\n" +
                            "</coordinator-app>";
            writer.write(wfApp);
            return coordName.toString();
        } catch (IOException e) {
            log.error("创建coordinator文件失败", e);
        } finally {
            if (null != writer) {
                try {
                    writer.close();
                } catch (IOException e) {
                    log.error("关闭流失败", e);
                }
            }
        }
        return null;
    }

    @Override
    public String createShellFileAndUpload(String shellFileName, String shellFilePath) {
        Writer writer = null;
        try {
            Path shellPath = new Path(fileSystem.getHomeDirectory(),shellFilePath.concat(shellFileName));
            writer = new OutputStreamWriter(fileSystem.create(shellPath));
            String shell =
                    "#!/bin/bash\n" +
                    "echo 'curl " + oozieConfig.getCallbackUrl() + "';\n" +
                    "curl -X GET " + oozieConfig.getCallbackUrl();
            writer.write(shell);
            return shellPath.toString();
        } catch (IOException e) {
            log.error("创建shell文件失败", e);
        } finally {
            if (null != writer) {
                try {
                    writer.close();
                } catch (IOException e) {
                    log.error("关闭流失败", e);
                }
            }
        }
        return null;
    }

    @Override
    public void executeCallback(String executeType, String taskType, String callbackId) {
        // TODO
        log.info("回调处理，executeType={}, taskType={}, callbackId={}", executeType, taskType, callbackId);
    }

    @Override
    public void killCoordinatorJob(String jobId) {
        OozieClient oozieClient = new OozieClient(oozieConfig.getUrl());
        oozieClient.setDebugMode(1);
        try {
            oozieClient.kill(jobId);
        } catch (OozieClientException e) {
            log.error("停止定时任务失败", e);
        }
    }
}
```

注意：上面调用的hdfs的接口是本文开头提到的前提条件，请到相应的文章集成hdfs，因为这是必须的，需要将脚本文件上传到hdfs才可以在oozie中引用到脚本文件。

控制器

```java
package com.winterchen.hadoopdemo.controller;

import com.winterchen.hadoopdemo.model.CoordinatorRequest;
import com.winterchen.hadoopdemo.model.WorkflowRequest;
import com.winterchen.hadoopdemo.service.OozieService;
import com.winterchen.hadoopdemo.utils.APIResponse;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiParam;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * @author winterchen
 * @version 1.0
 * @date 2020/11/25 11:10 上午
 * @description TODO
 **/
@Api(tags = "oozie调度任务")
@RequestMapping("/oozie")
@RestController
public class OozieController {

    @Autowired
    private OozieService oozieService;

    @ApiOperation("提交workflow任务")
    @PostMapping("/job/workflow")
    public APIResponse<String> submitWorkflowJob(
        @RequestBody WorkflowRequest workflowRequest
    ) {
        return APIResponse.success(oozieService.submitWorkflow(workflowRequest));
    }

    @ApiOperation("提交coordinator定时调度任务")
    @PostMapping("/job/coordinator")
    public APIResponse<String> submitCoordJob(
            @RequestBody CoordinatorRequest coordinatorRequest
            ) {
        return APIResponse.success(oozieService.submitCoordinator(coordinatorRequest));
    }

    @ApiOperation("停止定时调度任务")
    @DeleteMapping("/{jobId}")
    public APIResponse<?> killCoordJob(
            @PathVariable("jobId")
            String jobId
    ) {
        oozieService.killCoordinatorJob(jobId);
        return APIResponse.success();
    }

    @ApiOperation("处理回调")
    @GetMapping("/callback")
    public APIResponse<?> executeCallback(
            @ApiParam(name = "executeType", value = "处理类型", required = true)
            @RequestParam(name = "executeType", required = true)
                    String executeType,
            @ApiParam(name = "taskType", value = "任务类型", required = true)
            @RequestParam(name = "taskType", required = true)
                    String taskType,
            @ApiParam(name = "callbackId", value = "回调编号", required = true)
            @RequestParam(name = "callbackId", required = true)
            String callbackId
    ) {
        oozieService.executeCallback(executeType, taskType, callbackId);
        return APIResponse.success();
    }

}
```

上面实现的主要功能有：提交workflow和coordinator任务，停止任务等功能；

处理回调并不是必须的，可以根据业务要求来实现各种个性化功能；

## 源码地址:

[WinterChenS/springboot-learning-experience](https://github.com/WinterChenS/springboot-learning-experience/tree/master/spring-boot-hadoop)

## 参考文档：

- [https://oozie-study.readthedocs.io/en/master/Official Document/02. Example/#java-api](https://oozie-study.readthedocs.io/en/master/Official%20Document/02.%20Example/#java-api)
- [https://timepasstechies.com/oozie-workflow-example-shell-action-end-end-configuration/](https://timepasstechies.com/oozie-workflow-example-shell-action-end-end-configuration/)
- [https://oozie.apache.org/docs/3.1.3-incubating/DG_CommandLineTool.html](https://oozie.apache.org/docs/3.1.3-incubating/DG_CommandLineTool.html)
- [https://www.programcreek.com/java-api-examples/?api=org.apache.oozie.client.OozieClient](https://www.programcreek.com/java-api-examples/?api=org.apache.oozie.client.OozieClient)