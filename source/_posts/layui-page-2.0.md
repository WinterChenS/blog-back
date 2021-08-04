---
layout: post
title: layui完美分页，ajax请求分页（真分页） 【2.0版本】
date:  2017-10-25 20:55
comments: true
tags: [layui]
brief: "layui 分页"
reward: true
categories: layui
keywords: layui
cover: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039844.jpg
image: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039844.jpg
---

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039844.jpg)
### 注意
**使用的layui版本为：layui-v2.0以上版本，如果v1.0版本请看我另外一篇博客 [ 《layui完美分页，ajax请求分页（真分页）》](https://winterchens.github.io/2017/10/25/layui-page-1.0/)**
<!--  more  -->

最近因为以为学者在看了我上一篇关于layui分页的博客遇到了问题，原因是因为使用了新版本2.x，导致有一些属性改变了，所以出了这篇新版本的博客，本文是根据上一篇博客改变而成，如有疑问请联系我 email：1085143002@qq.com
### 完整代码：

```html
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="renderer" content="webkit">
	<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
	<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
	<meta name="apple-mobile-web-app-status-bar-style" content="black">
	<meta name="apple-mobile-web-app-capable" content="yes">
	<meta name="format-detection" content="telephone=no">
    <link  rel="icon" href="static/images/titleLogo.png"  />
    <title>门店管理后台</title>
    <link rel="stylesheet" href="static/layui/plugins/layui/css/layui.css" media="all" />
    <!-- <link rel="stylesheet" type="text/css" href="static/css/reset.css">
    <link rel="stylesheet" type="text/css" href="static/css/commend.css"> -->
    <!-- <link rel="stylesheet" href="static/css/jqpagination.css" /> -->
    <!-- <link rel="stylesheet" type="text/css" href="static/css/shopCustomerManager.css"> -->
    <script type="text/javascript" src="static/js/jquery-3.1.1.min.js"></script>
    <script type="text/javascript" src="static/layui/plugins/layui/layui.js"></script>
    <!-- <script type="text/javascript" src="static/js/jquery.jqpagination.js"></script> -->
   	<script type="text/javascript">
	   	$(document).ready(function(){
	   		  //ajax请求后台数据
		      getShopCustomerManagePageInfo();
		      
		
	   		  //点击搜索时 搜索数据
	   		  $("#selectButton").click(function(){ 
	   			getShopCustomerManagePageInfo();
	   			currentPageAllAppoint = 1; //当点击搜索的时候，应该回到第一页
	   			toPage();//然后进行分页的初始化
	   			
	   	      })
	   	   toPage();
	   	});
	   	
	  	//分页参数设置 这些全局变量关系到分页的功能
	   	var startAllAppoint = 0;//开始页数
	   	var limitAllAppoint = 10;//每页显示数据条数
	   	var currentPageAllAppoint = 1;//当前页数
	   	var dataLength = 0;//数据总条数
	   	//ajax请求后台数据
	   	function getShopCustomerManagePageInfo(){
	   		$.ajax({
	   			type:"post",
	   			async:false,
	   			url:"list_shop_customers_info",
	   			data:{start:startAllAppoint, limit:limitAllAppoint,selectValue:$("#selectValue").val()},
	   			success:function(data,status){
	   				data=eval("("+data+")");
	   				getShopCustomesInfo(data.root);
	   				startAllAppoint = data.currentResult;//当前页数(后台返回)
	   				dataLength  = data.total;//数据总条数
	   			}
	   		});
	   		
	   	}
	   	
	   
	   	
	   	function getShopCustomesInfo(data){
	   		var s = "<tr><th>姓名</th><th>性别</th><th>电话</th><th>备案楼盘</th><th>已成交</th><th>归属经纪人</th><th>添加时间</th></tr>";
	   		$.each(data,function(v,o){
	   				s+='<tr><td>'+o.cusName+'</td>';
	   				s+='<td>'+o.cusSex+'</td>';
	   				s+='<td>'+o.phone+'</td>';
	   				s+='<td>'+o.records+'</td>';
	   				s+='<td>'+o.alreadyDeal+'</td>';
	   				s+='<td>'+o.theMedi+'</td>';
	   				s+='<td>'+o.addTime+'</td></tr>';
	   		});

	   		if(data.length>0){
	   			$("#t_customerInfo").html(s);
	   		}else{
	   			$("#page1").hide();
	   			$("#t_customerInfo").html("<br/><span style='width:10%;height:30px;display:block;margin:0 auto;'>暂无数据</span>");
	   		}
	   		
	   		
	   	}
   		
	   	
	   	
	   	function toPage(){
	   		
	   		layui.use(['form', 'laypage', 'layedit','layer', 'laydate'], function() {
				var form = layui.form(),
					layer = layui.layer,
					layedit = layui.layedit,
					laydate = layui.laydate,
					laypage = layui.laypage;
				
				var nums = 10;
				//调用分页
				  laypage({
				    cont: 'paged'
				    ,count: dataLength //这个是后台返回的数据的总条数
				    ,limit: limitAllAppoint   //每页显示的数据的条数,layui会根据count，limit进行分页的计算
				    ,curr: currentPageAllAppoint
				    ,skip: true
				    ,jump: function(obj, first){
				    	
				    	currentPageAllAppoint = obj.curr;
				    	startAllAppoint = (obj.curr-1)*obj.limit;
				      //document.getElementById('biuuu_city_list').innerHTML = render(obj, obj.curr);
				      if(!first){ //一定要加此判断，否则初始时会无限刷新
				      getShopCustomerManagePageInfo();//一定要把翻页的ajax请求放到这里，不然会请求两次。
				          //location.href = '?page='+obj.curr;
				        }
				    }
				  });
				
				
			});
	   	};
	   	
   	</script>
</head>
<body>
	<div class="admin-main">
	
	
				<blockquote class="layui-elem-quote">
				<form class="layui-form" action="" >
				<div class="layui-form-item">
				<div class="layui-input-inline">
					<input type="text" id="selectValue" lay-verify="required" placeholder="客户姓名，电话" autocomplete="off" class="layui-input">
			    </div>
			    <button class="layui-btn" type="button" id="selectButton">搜索</button>
				</div>
				</form>
				<span><a href="shop_customer_manager_page_info">显示所有客户</a></span>
				</blockquote>
				<fieldset class="layui-elem-field">
					<legend>客户列表</legend>
					<div class="layui-field-box layui-form">
						<table class="layui-table admin-table" id="t_customerInfo">
							
						</table>
					</div>
				</fieldset>
				<div class="admin-table-page">
					<div id="paged" class="page">
					</div>
				</div>
			</div>
	
   
</body>
</html>
```

### java代码：

```java

/**
	 * shop 客户管理 list
	 * @param start
	 * @param limit
	 * @param selectValue
	 */
	@ResponseBody
	@RequestMapping("/list_shop_customers_info")
	public Object listShopCustomerInfo(Integer start, Integer limit, String selectValue) {
		Page page = new Page();
		page.setStart(start);
		page.setLimit(limit);
		// 获取session中的用户信息
		User u = (User) this.request.getSession().getAttribute("userInfo");
		// 获取持久化用户对象
		User user = userService.findById(u.getUserId());
		if (user != null) {
			projectCustomerService.findShopCustomersByUser(user, selectValue, page);
			return page;
		}
	}
```

### sevice层

```java
@Override
	public void findShopCustomersByUser(User user, String selectValue, Page page) {
		List cmList = new ArrayList<>();
		int total = 0;
		if(user!=null && user.getParentId()!=null && !user.getParentId().equals("")){
			String hql = "from ShopCustomers as model where model.shopId = " + Integer.parseInt(user.getParentId());
			if(selectValue!=null && !selectValue.equals("")){
				hql+="and model.shopCustomerName like '%" +selectValue+"%' or model.shopCustomerPhone like '%" +selectValue+"%'";
			}
			List<ShopCustomers> list = baseDao.findByHql(hql,page.getStart(),page.getLimit());
			for(ShopCustomers sc : list){
				User u = (User) baseDao.loadById(User.class, sc.getUserId());
				String cGRSHql = "select count(*) from GuideRecords where shopCustomerId = '"+sc.getShopCustomerId()+"'";
				String cDealHql = "select count(*) from GuideRecords where shopCustomerId = '"+sc.getShopCustomerId()+"' and isDeal = 1";
				int floorCounts = baseDao.countQuery(cGRSHql);//备案楼盘数
				int dealCounts = baseDao.countQuery(cDealHql);//已成交数
				CustomerManager cm = new CustomerManager();
				CustomerManager cmObj = cm.createCusManObj(sc,u);
				cmObj.setRecords(floorCounts);
				cmObj.setAlreadyDeal(dealCounts);
				cmList.add(cmObj);
			}
			String cHql = "select count(*) "+hql;
			total = baseDao.countQuery(cHql);
		}
		page.setRoot(cmList);
		page.setTotal(total);
	}
```
### 分页对象

```java
package com.sc.tradmaster.utils;

import java.util.List;
/**
 * 分页对象
 * @author grl 2017-01-05
 *
 */
public class Page {
	/** 总记录数 */
	private int total;
	/** 分页结果 */
	private List root;
	/** 开始页码 */
	private int start;
	/** 每页多少 */
	private int limit;
	/** 查询条件 */
	private String wheres;
	
	private int currentPage;	//当前页
	private int currentResult;	//当前记录起始索引
	private int totalPage;		//总页数

	public int getCurrentPage() {
		if(currentPage<=0)
			currentPage = 1;
		return currentPage;
	}

	public void setCurrentPage(int currentPage) {
		this.currentPage = currentPage;
	}

	public int getCurrentResult() {
		currentResult = (getCurrentPage()-1)*getLimit();
		if(currentResult<0)
			currentResult = 0;
		return currentResult;
	}

	public void setCurrentResult(int currentResult) {
		this.currentResult = currentResult;
	}

	public int getTotalPage() {
		if(total%limit==0)
			totalPage = total/limit;
		else
			totalPage = total/limit+1;
		return totalPage;
	}

	public void setTotalPage(int totalPage) {
		this.totalPage = totalPage;
	}

	public int getTotal() {
		return total;
	}

	public void setTotal(int total) {
		this.total = total;
	}

	public List getRoot() {
		return root;
	}

	public void setRoot(List root) {
		this.root = root;
	}

	public int getStart() {
		return start;
	}

	public void setStart(int start) {
		this.start = start;
	}

	public int getLimit() {
		return limit;
	}

	public void setLimit(int limit) {
		this.limit = limit;
	}

	public String getWheres() {
		return wheres;
	}

	public void setWheres(String wheres) {
		this.wheres = wheres;
	}
	
	@Override
	public String toString() {
		return start+" "+total +" " +root;
	}

}
```


如果遇到问题请联系我