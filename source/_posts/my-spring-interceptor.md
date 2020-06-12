---
layout: post
title: spring中添加自定义的拦截器
date:  2018-05-09 16:48
comments: true
tags: [spring]
brief: "spring"
reward: true
categories: spring
cover: https://images.unsplash.com/photo-1522199794616-8a62b541f762?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=71b5877630deb9ab5996f91cc61b43f7&auto=format&fit=crop&w=2104&q=80
---


![](https://images.unsplash.com/photo-1522199794616-8a62b541f762?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=71b5877630deb9ab5996f91cc61b43f7&auto=format&fit=crop&w=2104&q=80)


要想实现自定义的拦截器，我们不得不讲讲spring中的处理程序拦截器，那么什么是处理程序拦截器呢？
<!--more-->

## 什么是spring中的处理程序拦截器？

要想了解拦截器在spring中的作用，我们首先要了解一下HTTP的请求执行链。

1. DispatcherServlet捕获每一个请求；

2. DispatcherServlet将接收到的URL和相应的Controller进行映射；

3. 在请求到达相应的Controller之前**拦截器**会进行请求处理；

4. 处理完成之后进行视图的解析；

5. 返回视图。

在第3步中，也就是今天最重要的内容，在请求到达Controller之前，请求可以被拦截器处理，这些拦截器就像过滤器。只有当URL找到对应于它们的处理器时才会调用它们。在通过拦截器(拦截器预处理，其实也可以说前置处理)进行前置处理后，请求最终到达controller。之后，发送请求生成视图。但是在这之前，拦截器还是有可能来再次处理它(拦截器后置处理)。只有在最后一次操作之后，视图解析器才能捕获数据并输出视图。

处理程序映射拦截器基于`org.springframework.web.servlet.HandlerInterceptor`接口。这个接口有三个方法

```java
public interface HandlerInterceptor {

  //请求发送到Controller之前调用
    default boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws Exception {

        return true;
    }

    //请求发送到Controller之后调用
    default void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler,
            @Nullable ModelAndView modelAndView) throws Exception {
    }

    //完成请求的处理的回调方法
    default void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler,
            @Nullable Exception ex) throws Exception {
    }

}
```

## 编写自定义的拦截器

要想编写自定义的拦截器，需要有两个步骤：

- 实现``HandlerInterceptor``接口和方法；

- 将自定义拦截器添加到MVC中。

下面我们来实现一下代码：

### 首先我们创建一个类`BaseInterceptor`

```java
/**
 * 实现HandlerInterceptor接口，自定义拦截器
 */
@Component
public class BaseInterceptor implements HandlerInterceptor {
    private static final Logger LOGGE = LoggerFactory.getLogger(BaseInterceptor.class);

      //实现前置方法
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object o) throws Exception {
        String uri = request.getRequestURI();

        LOGGE.info("UserAgent: {}", request.getHeader(USER_AGENT));
        LOGGE.info("用户访问地址: {}, 来路地址: {}", uri, IPKit.getIpAddrByRequest(request));


      //拦截器处理用户权限
        if (uri.startsWith("/admin") && !uri.startsWith("/admin/login")) {
            response.sendRedirect(request.getContextPath() + "/admin/login");
            return false;
        }

        return true;
    }

    @Override
    public void postHandle(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse, Object o, ModelAndView modelAndView) throws Exception {
        //这个方法可以往request中添加一些公共的工具类给前端页面进行调用

    }



    @Override
    public void afterCompletion(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse, Object o, Exception e) throws Exception {
        //当请求处理完成调用
    }
}
```

以上的自定义拦截器实现类中，我们实现了`HandlerInterceptor`接口，并且实现了三个方法：`preHandle`、`postHandle`、`afterCompletion`。

在实际的应用中呢，我们常常可以在请求处理的前置方法``preHandle``中进行权限的验证，`postHandle`后置方法在实际的使用当中可以往request中添加一些公共的工具类给前端页面进行调用。

### 创建一个类`WebMvcConfig`实现`WebMvcConfigurer`接口

```java
/**
 * 向MVC中添加自定义组件
 * Created by Donghua.Chen on 2018/4/30.
 */
@Component
public class WebMvcConfig implements WebMvcConfigurer {

    @Autowired
    private BaseInterceptor baseInterceptor;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(baseInterceptor);
    }


}
```

这个类的主要作用就是将我们刚才自定义的拦截器组件添加到MVC中去。

以上我们就完成了自定义拦截器的全部过程，是不是很简单呢？
