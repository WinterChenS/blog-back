---
layout: post
title: springboot集成hadoop实战
date: 2020-12-01 18:43
comments: true
tags: [hadoop, hdfs, springboot]
brief: [share]
reward: true
categories: hadoop
keywords: hadoop, hdfs, springboot
cover: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046750241518.jpg
image: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046751576454.jpg
---


springboot集成hadoop实现hdfs增删改查

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

				<!-- 中文分词器 -->
        <dependency>
            <groupId>cn.bestwu</groupId>
            <artifactId>ik-analyzers</artifactId>
            <version>5.1.0</version>
        </dependency>
```

## 配置

hdfs的配置

```yaml
hdfs:
  hdfsPath: hdfs://bigdata-master:8020
  hdfsName: bigdata-master
```

将fileSystem配置并注册到spring容器

```java
@Slf4j
@Configuration
public class HadoopHDFSConfiguration {

    @Value("${hdfs.hdfsPath}")
    private String hdfsPath;
    @Value("${hdfs.hdfsName}")
    private String hdfsName;

    @Bean
    public org.apache.hadoop.conf.Configuration  getConfiguration(){
        org.apache.hadoop.conf.Configuration configuration = new org.apache.hadoop.conf.Configuration();
        configuration.set("fs.defaultFS", hdfsPath);
        return configuration;
    }

    @Bean
    public FileSystem getFileSystem(){
        FileSystem fileSystem = null;
        try {
            fileSystem = FileSystem.get(new URI(hdfsPath), getConfiguration(), hdfsName);
        } catch (IOException e) {
            // TODO Auto-generated catch block
            log.error(e.getMessage());
        } catch (InterruptedException e) {
            // TODO Auto-generated catch block
            log.error(e.getMessage());
        } catch (URISyntaxException e) {
            // TODO Auto-generated catch block
            log.error(e.getMessage());
        }
        return fileSystem;
    }

}
```

## 增删改查

```java
public interface HDFSService {

		// 创建文件夹
    boolean makeFolder(String path);
		// 是否存在文件
    boolean existFile(String path);
		
    List<Map<String, Object>> readCatalog(String path);

    boolean createFile(String path, MultipartFile file);

    String readFileContent(String path);

    List<Map<String, Object>> listFile(String path);

    boolean renameFile(String oldName, String newName);

    boolean deleteFile(String path);

    boolean uploadFile(String path, String uploadPath);

    boolean downloadFile(String path, String downloadPath);

    boolean copyFile(String sourcePath, String targetPath);

    byte[] openFileToBytes(String path);

    BlockLocation[] getFileBlockLocations(String path);

}
```

```java
@Slf4j
@Service
public class HDFSServiceImpl implements HDFSService {

    private static final int bufferSize = 1024 * 1024 * 64;

    @Autowired
    private FileSystem fileSystem;

    @Override
    public boolean makeFolder(String path) {
        boolean target = false;
        if (StringUtils.isEmpty(path)) {
            return false;
        }
        if (existFile(path)) {
            return true;
        }
        Path src = new Path(path);
        try {
            target = fileSystem.mkdirs(src);
        } catch (IOException e) {
            log.error(e.getMessage());
        }
        return target;
    }

    @Override
    public boolean existFile(String path) {
        if (StringUtils.isEmpty(path)){
            return false;
        }
        Path src = new Path(path);
        try {
            return fileSystem.exists(src);
        } catch (IOException e) {
            log.error(e.getMessage());
        }
        return false;
    }

    @Override
    public List<Map<String, Object>> readCatalog(String path) {
        if (StringUtils.isEmpty(path)){
            return Collections.emptyList();
        }
        if (!existFile(path)){
            log.error("catalog is not exist!!");
            return Collections.emptyList();
        }

        Path src = new Path(path);
        FileStatus[] fileStatuses = null;
        try {
            fileStatuses = fileSystem.listStatus(src);
        } catch (IOException e) {
            log.error(e.getMessage());
        }
        List<Map<String, Object>> result = new ArrayList<>(fileStatuses.length);

        if (null != fileStatuses && 0 < fileStatuses.length) {
            for (FileStatus fileStatus : fileStatuses) {
                Map<String, Object> cataLogMap = new HashMap<>();
                cataLogMap.put("filePath", fileStatus.getPath());
                cataLogMap.put("fileStatus", fileStatus);
                result.add(cataLogMap);
            }
        }
        return result;
    }

    @Override
    public boolean createFile(String path, MultipartFile file) {
        boolean target = false;
        if (StringUtils.isEmpty(path)) {
            return false;
        }
        String fileName = file.getName();
        Path newPath = new Path(path + "/" + fileName);

        FSDataOutputStream outputStream = null;
        try {
            outputStream = fileSystem.create(newPath);
            outputStream.write(file.getBytes());
            target = true;
        } catch (IOException e) {
            log.error(e.getMessage());
        } finally {
            if (null != outputStream) {
                try {
                    outputStream.close();
                } catch (IOException e) {
                    log.error(e.getMessage());
                }
            }
        }
        return target;
    }

    @Override
    public String readFileContent(String path) {
        if (StringUtils.isEmpty(path)){
            return null;
        }

        if (!existFile(path)) {
            return null;
        }

        Path src = new Path(path);

        FSDataInputStream inputStream = null;
        StringBuilder sb = new StringBuilder();
        try {
            inputStream = fileSystem.open(src);
            String lineText = "";
            while ((lineText = inputStream.readLine()) != null) {
                sb.append(lineText);
            }
        } catch (IOException e) {
            log.error(e.getMessage());
        } finally {
            if (null != inputStream) {
                try {
                    inputStream.close();
                } catch (IOException e) {
                    log.error(e.getMessage());
                }
            }
        }
        return sb.toString();
    }

    @Override
    public List<Map<String, Object>> listFile(String path) {
        if (StringUtils.isEmpty(path)) {
            return Collections.emptyList();
        }
        if (!existFile(path)) {
            return Collections.emptyList();
        }
        List<Map<String,Object>> resultList = new ArrayList<>();

        Path src = new Path(path);
        try {
            RemoteIterator<LocatedFileStatus> fileIterator = fileSystem.listFiles(src, true);
            while (fileIterator.hasNext()) {
                LocatedFileStatus next = fileIterator.next();
                Path filePath = next.getPath();
                String fileName = filePath.getName();
                Map<String, Object> map = new HashMap<>();
                map.put("fileName", fileName);
                map.put("filePath", filePath.toString());
                resultList.add(map);
            }
        } catch (IOException e) {
            log.error(e.getMessage());
        }

        return resultList;
    }

    @Override
    public boolean renameFile(String oldName, String newName) {
        boolean target = false;
        if (StringUtils.isEmpty(oldName) || StringUtils.isEmpty(newName)) {
            return false;
        }
        Path oldPath = new Path(oldName);
        Path newPath = new Path(newName);
        try {
            target = fileSystem.rename(oldPath, newPath);
        } catch (IOException e) {
            log.error(e.getMessage());
        }

        return target;
    }

    @Override
    public boolean deleteFile(String path) {
        boolean target = false;
        if (StringUtils.isEmpty(path)) {
            return false;
        }
        if (!existFile(path)) {
            return false;
        }
        Path src = new Path(path);
        try {
            target = fileSystem.deleteOnExit(src);
        } catch (IOException e) {
            log.error(e.getMessage());
        }
        return target;
    }

    @Override
    public boolean uploadFile(String path, String uploadPath) {
        if (StringUtils.isEmpty(path) || StringUtils.isEmpty(uploadPath)) {
            return false;
        }

        Path clientPath = new Path(path);

        Path serverPath = new Path(uploadPath);

        try {
            fileSystem.copyFromLocalFile(false,clientPath,serverPath);
            return true;
        } catch (IOException e) {
            log.error(e.getMessage(), e);
        }
        return false;
    }

    @Override
    public boolean downloadFile(String path, String downloadPath) {
        if (StringUtils.isEmpty(path) || StringUtils.isEmpty(downloadPath)) {
            return false;
        }

        Path clienPath = new Path(path);

        Path targetPath = new Path(downloadPath);

        try {
            fileSystem.copyToLocalFile(false,clienPath, targetPath);
            return true;
        } catch (IOException e) {
            log.error(e.getMessage());
        }
        return false;
    }

    @Override
    public boolean copyFile(String sourcePath, String targetPath) {
        if (StringUtils.isEmpty(sourcePath) || StringUtils.isEmpty(targetPath)) {
            return false;
        }

        Path oldPath = new Path(sourcePath);

        Path newPath = new Path(targetPath);

        FSDataInputStream inputStream = null;
        FSDataOutputStream outputStream = null;

        try {
            inputStream = fileSystem.open(oldPath);
            outputStream = fileSystem.create(newPath);

            IOUtils.copyBytes(inputStream,outputStream,bufferSize,false);
            return true;
        } catch (IOException e) {
            log.error(e.getMessage());
        } finally {
            if (null != inputStream) {
                try {
                    inputStream.close();
                } catch (IOException e) {
                    log.error(e.getMessage());
                }
            }
            if (null != outputStream) {
                try {
                    outputStream.close();
                } catch (IOException e) {
                    log.error(e.getMessage());
                }
            }
        }
        return false;
    }

    @Override
    public byte[] openFileToBytes(String path) {

        if (StringUtils.isEmpty(path)) {
            return null;
        }

        if (!existFile(path)) {
            return null;
        }

        Path src = new Path(path);
        byte[] result = null;
        FSDataInputStream inputStream = null;
        try {
            inputStream = fileSystem.open(src);
            result = IOUtils.readFullyToByteArray(inputStream);
        } catch (IOException e) {
            log.error(e.getMessage());
        } finally {
            if (null != inputStream){
                try {
                    inputStream.close();
                } catch (IOException e) {
                    log.error(e.getMessage());
                }
            }
        }

        return result;
    }

    @Override
    public BlockLocation[] getFileBlockLocations(String path) {
        if (StringUtils.isEmpty(path)) {
            return null;
        }
        if (!existFile(path)) {
            return null;
        }
        BlockLocation[] blocks = null;
        Path src = new Path(path);
        try{
            FileStatus fileStatus = fileSystem.getFileStatus(src);
            blocks = fileSystem.getFileBlockLocations(fileStatus, 0, fileStatus.getLen());
        }catch(Exception e){
            log.error(e.getMessage());
        }
        return blocks;
    }
}
```

## mapReduce

```java
package com.winterchen.hadoopdemo.reduce;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Reducer;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/*
 * 继承Reducer类需要定义四个输出、输出类型泛型：
 * 四个泛型类型分别代表：
 * KeyIn        Reducer的输入数据的Key，这里是每行文字中的单词"hello"
 * ValueIn      Reducer的输入数据的Value，这里是每行文字中的次数
 * KeyOut       Reducer的输出数据的Key，这里是每行文字中的单词"hello"
 * ValueOut     Reducer的输出数据的Value，这里是每行文字中的出现的总次数
 */
public class WordReduce extends Reducer<Text, IntWritable, Text, IntWritable> {

    private IntWritable result = new IntWritable();
    private List<String> textList = new ArrayList<>();

    @Override
    protected void reduce(Text key, Iterable<IntWritable> values, Context context) throws IOException, InterruptedException {
        int sum = 0;
        for (IntWritable val : values) {
            sum += val.get();
        }
        result.set(sum);
        context.write(key, result);

        String keyStr = key.toString();

        // 使用分词器，内容已经被统计好了，直接输出即可
        if (textList.contains(keyStr)) {
            System.out.println("============ " + keyStr + " 统计分词为: " + sum + " ============");
        }
    }
}
```

```java
package com.winterchen.hadoopdemo.configuration;

import com.winterchen.hadoopdemo.HadoopDemoApplication;
import com.winterchen.hadoopdemo.mapper.WordMapper;
import com.winterchen.hadoopdemo.reduce.WordReduce;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.io.IOException;

@Component
public class ReduceJobsConfiguration {

    @Value("${hdfs.hdfsPath}")
    private String hdfsPath;

    /**
     * 获取HDFS配置信息
     *
     * @return
     */
    public Configuration getConfiguration() {
        Configuration configuration = new Configuration();
        configuration.set("fs.defaultFS", hdfsPath);
        configuration.set("mapred.job.tracker", hdfsPath);
        return configuration;
    }

    /**
     * 获取单词统计的配置信息
     *
     * @param jobName
     * @param inputPath
     * @param outputPath
     * @throws IOException
     * @throws ClassNotFoundException
     * @throws InterruptedException
     */
    public void getWordCountJobsConf(String jobName, String inputPath, String outputPath)
            throws IOException, ClassNotFoundException, InterruptedException {
        Configuration conf = getConfiguration();
        Job job = Job.getInstance(conf, jobName);

        job.setMapperClass(WordMapper.class);
        job.setCombinerClass(WordReduce.class);
        job.setJarByClass(HadoopDemoApplication.class);
        job.setReducerClass(WordReduce.class);

        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);

        FileInputFormat.addInputPath(job, new Path(inputPath));
        FileOutputFormat.setOutputPath(job, new Path(outputPath));
        job.waitForCompletion(true);
    }

    @PostConstruct
    public void getPath() {
        hdfsPath = this.hdfsPath;
    }

    public String getHdfsPath() {
        return hdfsPath;
    }
}
```

```java
public interface MapReduceService {

    void wordCount(String jobName, String inputPath, String outputPath) throws Exception;

}
```

```java
package com.winterchen.hadoopdemo.service.impl;

import com.winterchen.hadoopdemo.configuration.ReduceJobsConfiguration;
import com.winterchen.hadoopdemo.service.HDFSService;
import com.winterchen.hadoopdemo.service.MapReduceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class MapReduceServiceImpl implements MapReduceService {

    @Autowired
    private HDFSService hdfsService;

    @Autowired
    private ReduceJobsConfiguration reduceJobsConfiguration;

    @Override
    public void wordCount(String jobName, String inputPath, String outputPath) throws Exception {
        if (StringUtils.isEmpty(jobName) || StringUtils.isEmpty(inputPath)) {
            return;
        }
        // 输出目录 = output/当前Job,如果输出路径存在则删除，保证每次都是最新的
        if (hdfsService.existFile(outputPath)) {
            hdfsService.deleteFile(outputPath);
        }
        reduceJobsConfiguration.getWordCountJobsConf(jobName, inputPath, outputPath);
    }
}
```

```java
package com.winterchen.hadoopdemo.service.impl;

import com.winterchen.hadoopdemo.configuration.ReduceJobsConfiguration;
import com.winterchen.hadoopdemo.service.HDFSService;
import com.winterchen.hadoopdemo.service.MapReduceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class MapReduceServiceImpl implements MapReduceService {

    @Autowired
    private HDFSService hdfsService;

    @Autowired
    private ReduceJobsConfiguration reduceJobsConfiguration;

    @Override
    public void wordCount(String jobName, String inputPath, String outputPath) throws Exception {
        if (StringUtils.isEmpty(jobName) || StringUtils.isEmpty(inputPath)) {
            return;
        }
        // 输出目录 = output/当前Job,如果输出路径存在则删除，保证每次都是最新的
        if (hdfsService.existFile(outputPath)) {
            hdfsService.deleteFile(outputPath);
        }
        reduceJobsConfiguration.getWordCountJobsConf(jobName, inputPath, outputPath);
    }
}
```

```java
@Slf4j
@Api(tags = "map reduce api")
@RestController
@RequestMapping("/api/v1/map-reduce")
public class MapReduceController {

    @Autowired
    private MapReduceService mapReduceService;

    @ApiOperation("count word")
    @PostMapping("/word/count")
    public APIResponse wordCount(
            @ApiParam(name = "jobName", required = true)
            @RequestParam(name = "jobName", required = true)
            String jobName,
            @ApiParam(name = "inputPath", required = true)
            @RequestParam(name = "inputPath", required = true)
            String inputPath,
            @ApiParam(name = "outputPath", required = true)
            @RequestParam(name = "outputPath", required = true)
            String outputPath
    ){
        try {
            mapReduceService.wordCount(jobName, inputPath, outputPath);
            return APIResponse.success();
        } catch (Exception e) {
            log.error(e.getMessage());
            return APIResponse.fail(e.getMessage());
        }
    }
}
```

以上就是日常开发中能使用到的基本的功能：hdfs的增删改查，以及MapReduce；

源码地址: 

[WinterChenS/springboot-learning-experience](https://github.com/WinterChenS/springboot-learning-experience/tree/master/spring-boot-hadoop)