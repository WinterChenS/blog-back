---
layout: post
title: mapstruct 高级用法之userid转换为username
date: 2020-11-30 18:30
comments: true
tags: [mapstruct]
brief: [share]
reward: true
categories: springboot
keywords: mapstruct
cover: http://img.winterchen.com/20201130182732.jpg
image: http://img.winterchen.com/20201130182732.jpg
---

![](http://img.winterchen.com/20201130182732.jpg)

> 题图：柯达胶片


mapstruct的简单用法就不讲了，看完这篇文章能获得什么呢？

- 1.普通用法：将userId转换为userName？
- 2.高级用法：一劳永逸的将userId转换为userName？

很多时候在数据库里面只有userid而没有username的冗余信息，在entity转换为dto，vo等模型的时候需要额外的设值，mapstruct可以很方便的进行对象之间的转换，那么接下来我们就开始吧

## 前提

```java
/**
 * @author winterchen
 * @version 1.0
 * @date 2020/11/27 4:52 下午
 * @description 项目信息
 **/
@Data
@Builder
@ToString
@ApiModel("项目信息")
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper=false)
public class ProjectDTO implements Serializable {

    private static final long serialVersionUID = -2601073448289463936L;

		// ... 省略部分字段
		
    @ApiModelProperty("创建人")
    private String createUserId;
		
		// 这里一定不能使用String类型，必须要自己包装一个简单的类型，因为mapstruct是根据类型进行转换的
    @ApiModelProperty("创建人名称")
    private SimpleUserDTO createUserName;

}
```

```java
@Data
@Builder
@ToString
@NoArgsConstructor
@AllArgsConstructor
@ApiModel("基本用户信息")
@EqualsAndHashCode(callSuper=false)
public class SimpleUserDTO implements Serializable {

    private static final long serialVersionUID = 6889842645997918707L;

    @ApiModelProperty("用户名")
    private String userName;

}
```

```java
/**
 * @author winterchen
 * @version 1.0
 * @date 2020/11/27 4:52 下午
 * @description 项目信息
 **/
@Data
@Builder
@ToString
@NoArgsConstructor
@AllArgsConstructor
@Document(collection = "project")
public class Project {

		// ... 省略部分字段   

    /**
     * 创建人
     */
    @CreatedBy
    private String createUserId;

    
}
```

## 普通用法

```java
/**
 * @author winterchen
 * @version 1.0
 * @date 2020/11/28 1:48 下午
 * @description
 **/
@Mapper(componentModel = "spring")
public abstract class ProjectMapping{
		
		// 博主这里使用的是mongodb，这里可以换成你对应的查询用户信息的类
		@Autowired
    protected MongoTemplate mongoTemplate;
		/**
		 * 这里的注释主要是指定需要转换的source到target的信息，mapstruct会根据类型进行相应的转换
		 * 比如 String-> SimpleUserDTO
		 * 所以我们需要指定属性名称，然后mapstruct会根据属性类型调用方法 SimpleUserDTO toConvertToUserName(String userId) 
		 **/
    @Mappings({
            @Mapping(target = "createUserName", source = "createUserId")
    })
    public abstract ProjectDTO toConvertToDto(Project project);

    public abstract List<ProjectDTO> toConvertToDtos(List<Project> projects);

		protected SimpleUserDTO toConvertToUserName(String userId) {
	        Query query = new Query(Criteria.where("id").is(userId));
	        User user = mongoTemplate.findOne(query, User.class);
	        if (null != user) {
	            SimpleUserDTO result = SimpleUserDTO.builder()
	                    .userName(user.getUserName())
	                    .build();
	            return result;
	        }
	        return null;
    }
}
```

- 注意点：没有使用interface而是使用abstract抽象类，主要原因是因为需要有自己的实现方法来转换userid到username

我们看看maven编译之后的实现类：

```java
@Generated(
    value = "org.mapstruct.ap.MappingProcessor",
    date = "2020-11-28T16:43:17+0800",
    comments = "version: 1.3.1.Final, compiler: javac, environment: Java 1.8.0_251 (Oracle Corporation)"
)
@Component
public class ProjectMappingImpl extends ProjectMapping {

    @Override
    public ProjectDTO toConvertToDto(Project project) {
        if ( project == null ) {
            return null;
        }
        ProjectDTOBuilder projectDTO = ProjectDTO.builder();
				// 重点看这里，mapstruct生成的实现类会自动调用我们定义的方法
        projectDTO.createUserName( toConvertToUserName( project.getCreateUserId() ) );
        projectDTO.createUserId( project.getCreateUserId() );
        return projectDTO.build();
    }

    @Override
    public List<ProjectDTO> toConvertToDtos(List<Project> projects) {
        if ( projects == null ) {
            return null;
        }

        List<ProjectDTO> list = new ArrayList<ProjectDTO>( projects.size() );
        for ( Project project : projects ) {
            list.add( toConvertToDto( project ) );
        }

        return list;
    }

		protected SimpleUserDTO toConvertToUserName(String userId) {
		        Query query = new Query(Criteria.where("id").is(userId));
		        User user = mongoTemplate.findOne(query, User.class);
		        if (null != user) {
		            SimpleUserDTO result = SimpleUserDTO.builder()
		                    .userName(user.getUserName())
		                    .build();
		            return result;
		        }
		        return null;
    }
}
```

返回的结果：

```json
{
  "code": 200,
  "data": {
    "createUserId": "5fb476444dfa732e47790966",
    "createUserName": {
      "userName": "winter"
    }
  },
  "message": "操作成功"
}
```

## 高级用法：一劳永逸型用法

所谓的一劳永逸主要是解决每次都要写实现就很烦了，所以就要实现写一次后面都不用实现了，思路是这样的，ProjectMapping抽象类继续往上抽象一层，将上述的转换方法抽到上一层，以后有需要转换userid到username的需求只需要继承那个抽象类（BaseMapping）

```java
/**
 * @author winterchen
 * @version 1.0
 * @date 2020/11/28 4:31 下午
 * @description 基本的mapping
 **/
public abstract class BaseMapping {

    @Autowired
    protected MongoTemplate mongoTemplate;

    protected SimpleUserDTO toConvertToUserName(String userId) {
        Query query = new Query(Criteria.where("id").is(userId));
        User user = mongoTemplate.findOne(query, User.class);
        if (null != user) {
            SimpleUserDTO result = SimpleUserDTO.builder()
                    .userName(user.getUserName())
                    .build();
            return result;
        }
        return null;
    }
}
```

```java
/**
 * @author winterchen
 * @version 1.0
 * @date 2020/11/28 1:48 下午
 * @description
 **/
@Mapper(componentModel = "spring")
public abstract class ProjectMapping extends BaseMapping{

    @Mappings({
            @Mapping(target = "createUserName", source = "createUserId")
    })
    public abstract ProjectDTO toConvertToDto(Project project);

    public abstract List<ProjectDTO> toConvertToDtos(List<Project> projects);

}
```

以上就可以使用了，只需要继承这个抽象类就可以，前提是DTO，VO中的属性类型是SimpleUserDTO

## 拓展

按照这种方式其实可以举一反三，以后遇到需要获取源对象内子对象的某个属性到DTO、VO的属性字段也可以使用这种方式