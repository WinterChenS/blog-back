---
layout: post
title: 当springMVC上下文尚未初始化的时候如何@Autowired注入对象呢？
date:  2018-05-30 09:45
comments: true
tags: [spring]
brief: "spring"
reward: true
categories: spring
keywords: spring, java
cover: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046776398970.jpg
image: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046776553776.jpg
---

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046776701619.jpg)

一个问题困扰了我一天，场景是这样的：

*  公司有一个独立的SSO用户权限验证中心，我负责的是公司的一个其他的独立项目；
*  每次用户session过期或者未登录的时候跳统一登录页面；
*  用户成功登录之后都会回调，回调的信息中有用户的userAccount；
*  此时需要根据用户的userAccount获取用户的详细信息；
*  权限系统提供了一个获取用户的接口；
<!-- more -->

遇到的问题：

*	使用的是shrio进行系统权限的控制，当用户在SSO登录页面成功登录之后会回调到shrio的配置类中；
*	需要在shrio的配置类中调用根据用户账号获取用户信息的接口：

```java
public class IecWepmShiroAuthService extends AbstractShiroAuthService<SessionUser> implements EnvironmentAware {

	@Autowired
    private TenantUserCloudService tenantUserCloudService;
}
```	

调用的就是这么一个接口

```java
@CloudServiceClient("gap-service-tenant-auth")
public interface TenantUserCloudService {

	@RequestMapping(
        value = {"/tenant/user/by-emp-no"},
        method = {RequestMethod.GET}
    )
    APIResponse<TenantUser> getTenantUserByEmpNo(@RequestParam(name = "tenantId",required = true) Integer var1, @RequestParam(name = "empNo",required = true) String var2);
}
```

如果按照下面的代码进行注入，那么由于shrio的初始化要先与springMVC，所以导致找不到相关处理的类；
```java

@Autowired
    private TenantUserCloudService tenantUserCloudService;
```

解决的思路就是：

* 首先不进行`tenantUserCloudService`的初始化，只有在调用该接口的时候进行初始化；
* 创建一个类实现`ApplicationContextAware`接口，实现这个接口可以很方便的从spring容器中获取bean；
* 机制就是**当调用这个接口的时候才从spring容器中获取这个bean**；

创建一个类实现`ApplicationContextAware`接口：

```java
//相当于给一个bean进行代理
public class DelegateBean implements ApplicationContextAware {
    private static final Logger logger = LoggerFactory.getLogger(DelegateBean.class);
    protected ApplicationContext applicationContext;
    protected Object target;
    protected String targetBeanName;
    protected Class targetBeanType;

    public DelegateBean(String targetBeanName) {
        this.targetBeanName = targetBeanName;
    }
	
    public DelegateBean(Class targetBeanType) {
        this.targetBeanType = targetBeanType;
    }
	
    public DelegateBean(ApplicationContext applicationContext, String targetBeanName) {
        this.applicationContext = applicationContext;
        this.targetBeanName = targetBeanName;
    }

    public DelegateBean(ApplicationContext applicationContext, Class targetBeanType) {
        this.applicationContext = applicationContext;
        this.targetBeanType = targetBeanType;
    }

    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        this.applicationContext = applicationContext;
    }
	//当调用这个方法的时候才从spring容器中获取bean；
    public Object target() {
        Assert.notNull(this.applicationContext, "A DelegateBean should be managed by ApplicationContext or pass ApplicationContext though constructor arg");
        if(this.target == null) {
            synchronized(this) {
                return this.target != null?this.target:(this.target = this.doGetBeanFromApplicationContext());
            }
        } else {
            return this.target;
        }
    }

    protected Object doGetBeanFromApplicationContext() {
        return this.targetBeanName != null?this.applicationContext.getBean(this.targetBeanName):(this.targetBeanType != null?this.applicationContext.getBean(this.targetBeanType):null);
    }
}
```

只是这样配置还是不够的，我们需要在spring初始化的时候将这个代理bean交给spring容器进行管理；

```java
@Configuration
public class IecWepmAutoConfiguration{

	@Bean
    @Qualifier("tenantUserCloudService")
    public DelegateBean tenantUserCloudService(){
        return new DelegateBean(TenantUserCloudService.class);
    }
}
```

然后再shrio的类中我们需要进行这样的使用：

```java
public class IecWepmShiroAuthService extends AbstractShiroAuthService<SessionUser> implements EnvironmentAware {
	@Autowired
    @Qualifier("tenantUserCloudService")
    private DelegateBean tenantUserCloudService;
	
	@Override
    public SessionUser doLogin(String userAccount, String userPwd) {
        
        //根据用户编号获取用户信息,调用target()是关键，只有在调用这个方法的时候才会从spring容器中获取信息
        APIResponse<TenantUser> tenantUserByEmpNo = ((TenantUserCloudService) tenantUserCloudService.target())
                .getTenantUserByEmpNo(TENANT_ID, userAccount);
        if ("success".equals(tenantUserByEmpNo.getCode()) && null != tenantUserByEmpNo.getData()){
            userAccount = tenantUserByEmpNo.getData().getDomainAccountList().get(0).getDomainAccount();
        }
        UserInfoDto userInfo = userService.getUserByAccount(userAccount);
        SessionUser sessionUser = new SessionUser();
        sessionUser.setUserId(Integer.valueOf(userAccount));
        AuthUtils.setSessionUser(sessionUser);
        // todo 返回的SessionUser 就是保存在session里的对象 通过 SessionUser sessionUser = (SessionUser) AuthUtils.getSessionUser(); 进行获取
        return sessionUser;
    }
}
```


关键： **以上的思路最主要的就是，在shrio初始化的时候仅仅只是初始化一个空壳，只有当使用那个bean的时候才从spring容器中获取bean并且注入，这样的好处就是当当前bean的声明周期还未开始的时候预留一个位置，当使用的时候才从spring容器中注入，这样不会导致项目启动的时候就会找不到bean**；






















































































