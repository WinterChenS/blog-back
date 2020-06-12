---
layout: post
title: jenkins 持续集成 docker服务到堡垒机
date: 2020-04-14 13:28
comments: true
tags: [docker,jenkins]
brief: [jenkins]
reward: true
categories: jenkins
cover: https://images.unsplash.com/photo-1583916832932-a658eeb1199d?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1491&q=80
---

## 简介

公司原来的项目发布很繁琐也很普通，最近捣鼓一下jenkins+docker，做一下一键发布，由于公司服务器都加了堡垒机，所以需要解决不能远程ssh部署，整体的思路如下：

1. jenkins使用pipeline脚本编写（更灵活，方便多套环境复制使用）；
2. 拉取代码并编译成jar包；
3. 将jar包编译为docker镜像；
4. 将镜像上传到本地私有仓库（速度快）
5. 调用写好的跑脚本的服务接口实现在堡垒机中实现docker镜像的新版本发布；

关于jenkins的安装方式一开始尝试了很多种方案：

- jenkins部署在docker容器内，使用远程docker rest api进行镜像打包上传，但是遇到很大的问题就是阿里云私有镜像仓库登录方式不一样，导致登录失败，而且不能使用脚本操作docker，因为jenkins容器内没有docker环境，如果安装docker in docker，这样就太麻烦了，在容器外面就有一套docker环境；(如果不依赖阿里云私有仓库，这种方案就没有关系了)
- jenkins安装在有docker环境的服务器内，那么可以使用shell脚本灵活的进行编译上传等操作（适用于比较灵活的使用场景）


## 开始：

### 依赖环境：
- jenkins
- docker


### jenkins安装

安装步骤请查询相关文档，这里就略过

### jenkins安装插件提速

```
cd {你的Jenkins工作目录}/updates  #进入更新配置位置

vim default.json

##替换软件源
:1,$s/http:\/\/updates.jenkins-ci.org\/download/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins/g
```

### 安装jenkins插件 HTTP Request
这个插件用于jenkins将docker镜像push到目标仓库之后调用堡垒机中发布服务进行docker镜像的发布

### 编写jenkins发布脚本

步骤：新建item -> 选择pipeline（流水线） -> 编辑流水线脚本

注意：
- 在输入框的左下角有：流水线语法，可以根据某些你需要用到的插件生成模板脚本，非常方便
- 脚本有一点需要注意，单引号内只能为文本不能使用变量，如果需要使用变量，使用双引号；


```
pipeline {
   agent any

   tools {
      // Install the Maven version configured as "M3" and add it to the path.
      maven "maven3.6.3"
   }
   
   //环境变量，一下变量名称都可以自定义，在后面的脚本中使用
   environment {
      //git仓库
	  GIT_REGISTRY = 'https://github.com/WinterChenS/my-site.git'
	  //分支
	  GIT_BRANCH = 'sit'
	  //profile
	  PROFILES = 'sit'
	  //如果仓库是私有的需要在凭证中添加凭证，然后把id写到这里
	  GITLAB_ACCESS_TOKEN_ID = '85465d36-4c3a-469f-b92f-f53dae47fd0c'
	  //服务名称
	  SERVICE_NAME = 'my-site'
	  //镜像名称,aaa_sit是命名空间，可以区分不同的环境
	  IMAGE_NAME = "127.0.0.1:8999/aaa_sit/${SERVICE_NAME}"
	  //镜像tag
	  TAG = "latest"
	  //远程发布服务的地址
	  REMOTE_EXECUTE_HOST = 'http://10.85.54.33:7017/shell'
	  //服务开放的端口
	  SERVER_PORT = '19070'
	  //日志目录，容器内目录
	  LOG_DIR = '/var/logs'
	  //宿主机目录
      MAIN_VOLUME = "${LOG_DIR}/jar_${env.SERVER_PORT}"
      //jvm参数
      JVM_ARG = "-server -Xms512m -Xmx512m  -XX:+HeapDumpOnOutOfMemoryError  -XX:HeapDumpPath=${LOG_DIR}/dump/dump-yyy.log  -XX:ErrorFile=${LOG_DIR}/jvm/jvm-crash.log"
   }
   
   

   stages {
      stage('Build') {
         steps {
            // 获取代码
            git credentialsId: "${env.GITLAB_ACCESS_TOKEN_ID}", url: "${env.GIT_REGISTRY}", branch: "${env.GIT_BRANCH}"

            // maven 打包
            sh "mvn -Dmaven.test.failure.ignore=true clean package -P ${env.PROFILES}"

         }

      }
      
      stage('Execute shell') {
	    // 将jar包拷贝到Dockerfile所在目录
		steps {
		    //注意，这里的目录一定要跟项目实际的目录结构要对应上
			sh "cp ${env.WORKSPACE}/${env.SERVICE_NAME}/target/*.jar ${env.WORKSPACE}/${env.SERVICE_NAME}/src/main/docker/${env.SERVICE_NAME}.jar"
		
		}
	  }
	  
	  
	 
	  
	  stage('Image Build And Push') {

		steps {
            //运行这些脚本的条件就是jenkins运行的服务器有docker环境
            //如果jdk版本是你自己编译成的docker镜像，那么首次编译的时候需要pull
			sh "echo '================开始拉取基础镜像jdk1.8================'"	
			//这里根据你的私有仓库而定，如果是使用公共镜像的openjdk那么可以略过这一步
			sh "docker pull 127.0.0.1:8999/jdk/jdk1.8:8u171"
			sh "echo '================基础镜像拉取完毕================'"
			
			sh "echo '================开始编译并上传镜像================'"
			//注意目录结构
			sh "cd ${env.WORKSPACE}/${env.SERVICE_NAME}/src/main/docker/ && docker build -t ${env.IMAGE_NAME}:${env.TAG} . && docker push ${env.IMAGE_NAME}:${env.TAG}"
			sh "echo '================镜像上传成功================'"
			
			sh "echo '================删除本地镜像================'"
			//删除本地镜像防止占用资源
			sh "docker rmi ${env.IMAGE_NAME}:${env.TAG}"
			
		}
		

	  }
	  
	  stage('Execute service') {

	    //请求堡垒机内的发布服务，具体代码后面会给出
		steps {
		    //以下整个脚本都依赖jenkins插件：HTTP Request
		    //将body转换为json
            script {
              def toJson = {
                input ->
                groovy.json.JsonOutput.toJson(input)
            }
			//body定义,根据实际情况而定
			def body = [
                imageName: "${env.IMAGE_NAME}",
                tag:"${env.TAG}",
                port:"${env.SERVER_PORT}",
                simpleImageName: "${env.SERVICE_NAME}",
                envs: [
                    JVM_ARGS: "${env.JVM_ARG}"
                ],
                volumes: ["${env.MAIN_VOLUME}:${env.LOG_DIR}"]
            ]
			
			sh "echo '================开始调用目标服务器发布================'"
			response = httpRequest acceptType: 'APPLICATION_JSON', consoleLogResponseBody: true, contentType: 'APPLICATION_JSON', httpMode: 'POST', requestBody: toJson(body), responseHandle: 'NONE', url: "${env.REMOTE_EXECUTE_HOST}"
		    sh "echo '================结束调用目标服务器发布================'"			
		}
		

	  }
   }
}
}
```



### 远程堡垒机发布服务

远程发布服务其实是一个很简单的执行脚本的服务

ShellRequestDTO.java
```java
package com.winterchen.jenkinsauto.dto;

import javax.validation.constraints.NotBlank;
import java.util.List;
import java.util.Map;

public class ShellRequestDTO {

    @NotBlank
    private String imageName;

    @NotBlank
    private String tag;

    @NotBlank
    private String simpleImageName;

    @NotBlank
    private String port;

    /**
     * 环境变量列表
     */
    private Map<String, String> envs;

    private List<String> volumes;

    public String getImageName() {
        return imageName;
    }

    public void setImageName(String imageName) {
        this.imageName = imageName;
    }

    public String getTag() {
        return tag;
    }

    public void setTag(String tag) {
        this.tag = tag;
    }

    public String getPort() {
        return port;
    }

    public void setPort(String port) {
        this.port = port;
    }

    public String getSimpleImageName() {
        return simpleImageName;
    }

    public void setSimpleImageName(String simpleImageName) {
        this.simpleImageName = simpleImageName;
    }

    public Map<String, String> getEnvs() {
        return envs;
    }

    public void setEnvs(Map<String, String> envs) {
        this.envs = envs;
    }

    public List<String> getVolumes() {
        return volumes;
    }

    public void setVolumes(List<String> volumes) {
        this.volumes = volumes;
    }

    @Override
    public String toString() {
        final StringBuilder sb = new StringBuilder("ShellRequestDTO{");
        sb.append("imageName='").append(imageName).append('\'');
        sb.append(", tag='").append(tag).append('\'');
        sb.append(", simpleImageName='").append(simpleImageName).append('\'');
        sb.append(", port='").append(port).append('\'');
        sb.append(", envs=").append(envs);
        sb.append(", volumes=").append(volumes);
        sb.append('}');
        return sb.toString();
    }
}

```

APIResponse.java
```java
package com.winterchen.jenkinsauto.dto;


public class APIRespose<T> {

    private Integer code;

    private T data;

    private String message;

    private Boolean success;


    public static APIRespose success(){
        APIRespose apiRespose = new APIRespose();
        apiRespose.setCode(200);
        apiRespose.setSuccess(true);
        return apiRespose;
    }

    public static APIRespose success(Object data) {
        APIRespose apiRespose = new APIRespose();
        apiRespose.setCode(200);
        apiRespose.setSuccess(true);
        apiRespose.setData(data);
        return apiRespose;
    }

    public static APIRespose fail(String message) {
        APIRespose apiRespose = new APIRespose();
        apiRespose.setCode(500);
        apiRespose.setSuccess(false);
        apiRespose.setMessage(message);
        return apiRespose;
    }

   //get,set省略
}

```

BaseController.java

```java
package com.winterchen.jenkinsauto.controller;

import com.winterchen.jenkinsauto.dto.APIRespose;
import com.winterchen.jenkinsauto.dto.ShellRequestDTO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.text.MessageFormat;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/shell")
public class BaseController {

    private static final Logger LOGGER = LoggerFactory.getLogger(BaseController.class);

    @PostMapping("")
    public APIRespose executeShell(
        @RequestBody
        @Validated
        ShellRequestDTO requestDTO
    ) {
        LOGGER.info("当前请求参数：" + requestDTO.toString());
        StringBuilder sb = new StringBuilder();
        try {
            doExecuteShell(requestDTO, sb);
            return APIRespose.success(sb.toString());
        } catch (Exception e) {
            return APIRespose.fail(e.getMessage());
        }
    }

    private synchronized void doExecuteShell(ShellRequestDTO requestDTO, StringBuilder sb) throws Exception{
        //停止旧的容器
        stopContainer(requestDTO.getSimpleImageName(), sb);
        //stopContainerByImageId(requestDTO.getImageName(), sb);
        //删除旧的容器
        removeContainer(requestDTO.getSimpleImageName(), sb);
        //removeContainerByImageId(requestDTO.getImageName(),sb);
        //删除旧的镜像
        removeImage(requestDTO.getImageName(), sb);
        removeNoneImages(sb);
        //拉取最新的镜像
        pullImage(requestDTO.getImageName(), requestDTO.getTag(), sb);
        //运行最新镜像
        runImage(requestDTO, sb);
    }


    private void pullImage(String imageName, String tag, StringBuilder sb) throws Exception{
        execute(MessageFormat.format("docker pull {0}:{1}", imageName, tag), sb);
    }

    private void stopContainer(String simpleImageName, StringBuilder sb) {
        try {
            execute("docker stop " + simpleImageName, sb);
        } catch (Exception e) {
            LOGGER.error("停止容器失败", e);
        }
    }



    private void removeImage(String imageName, StringBuilder sb)  {
        try {
            execute("docker rmi -f " + imageName, sb);
        } catch (Exception e) {
            LOGGER.error("删除镜像失败", e);
        }
    }

    private void removeNoneImages(StringBuilder sb) {
        try{
            execute("docker ps -a | grep `docker images -f 'dangling=true' -q` | awk '{print $1}'", sb);
            execute("docker stop $(docker ps -a | grep `docker images -f 'dangling=true' -q` | awk '{print $1}')", sb);
            execute("docker ps -a | grep `docker images -f 'dangling=true' -q` | awk '{print $1}'",sb);
            execute("docker rm  $(docker ps -a | grep `docker images -f 'dangling=true' -q` | awk '{print $1}')", sb);
            execute("docker images -f 'dangling=true'|awk '{print $3}'", sb);
            execute("docker image rm -f  `docker images -f 'dangling=true'|awk '{print $3}'`", sb);
        } catch (Exception e) {
            LOGGER.error("删除none镜像失败", e);
        }
    }


    private void removeContainer(String simpleImageName, StringBuilder sb) {
        try {
            execute("docker rm " + simpleImageName, sb);
        } catch (Exception e) {
            LOGGER.error("删除容器失败", e);
        }
    }


    private void runImage(ShellRequestDTO requestDTO, StringBuilder sb) throws Exception{
        StringBuilder shell = new StringBuilder();
        shell.append("docker run -p ").append(requestDTO.getPort()).append(":").append(requestDTO.getPort());
        shell.append(" --network=host ");
        shell.append(" --name=").append(requestDTO.getSimpleImageName());
        shell.append(" -d ");
        formatEnv(requestDTO.getEnvs(), shell);
        formatVolumes(requestDTO.getVolumes(), shell);
        shell.append(requestDTO.getImageName()).append(":").append(requestDTO.getTag());
        execute(shell.toString(), sb);
    }

    private void formatVolumes(List<String> volumes, StringBuilder shell) {
        if (volumes == null || 0 == volumes.size()) {
            return;
        }
        volumes.forEach(volume -> {
            shell.append(" -v ");
            shell.append(" '").append(volume).append("' ");
        });
    }

    private void formatEnv(Map<String, String> env, StringBuilder shell) {
        if (env == null || env.isEmpty()) {
            return;
        }
        for (Map.Entry<String, String> entry : env.entrySet()) {
            shell.append(" -e ");
            shell.append(entry.getKey()).append("='").append(entry.getValue()).append("' ");
        }
    }


    private void execute(String command, StringBuilder sb) throws Exception {
        BufferedReader infoInput = null;
        BufferedReader errorInput = null;
        try {
            LOGGER.info("======================当前执行命令======================");
            LOGGER.info(command);
            LOGGER.info("======================当前执行命令======================");
            //执行脚本并等待脚本执行完成
            String[] commands = { "/bin/sh", "-c", command };
            Process process = Runtime.getRuntime().exec(commands);
            //写出脚本执行中的过程信息
            infoInput = new BufferedReader(new InputStreamReader(process.getInputStream()));
            errorInput = new BufferedReader(new InputStreamReader(process.getErrorStream()));
            String line = "";
            while ((line = infoInput.readLine()) != null) {
                sb.append(line).append(System.lineSeparator());
                LOGGER.info(line);
            }
            while ((line = errorInput.readLine()) != null) {
                sb.append(line).append(System.lineSeparator());
                LOGGER.error(line);
            }
            //阻塞执行线程直至脚本执行完成后返回
            process.waitFor();
        } finally {
            try {
                if (infoInput != null) {
                    infoInput.close();
                }
                if (errorInput != null) {
                    errorInput.close();
                }
            } catch (IOException e) {

            }
        }
    }
}

```


## 相关资源

- [docker rest api 官方文档](https://docs.docker.com/engine/api/v1.24/)
- [jenkins 官方文档](https://jenkins.io/zh/doc/)
- [docker 官方文档](https://docs.docker.com/engine/)



