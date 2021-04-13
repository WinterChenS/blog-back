---
layout: post
title: Java导出Excel文档（poi），并上传到腾讯云对象存储服务器
date:  2017-10-21 20:00
comments: true
tags: [java,poi]
brief: "工具类"
reward: true
categories: JavaUtils
keywords: java,poi
cover: http://img.winterchen.com/john-salzarulo-342868-unsplash.jpg
image: http://img.winterchen.com/john-salzarulo-342868-unsplash.jpg
---
![](http://img.winterchen.com/john-salzarulo-342868-unsplash.jpg)
### 需求
**后台生成周报月报季报年报Excel，将文件下载链接推送给对应客户**
<!--  more  -->

### 开发思路：
**1.根据选定日期生成周报，月报，季报，年报数据**
**2.将这些数据报告生成Excel表格**
**3.把生成的文件上传到腾讯云对象存储服务器**
**4.将服务器返回的url存储到数据库**



### 工具
**[poi-3.14-20160307.jar(点击可下载)](http://download.csdn.net/download/yaosir12/9475344)**

### 数据

获取数据部分省略了

### 代码

**主方法**
```java
public boolean addReportExcelToCloud(ReportResult rr) {

		OutputStream out = new ByteArrayOutputStream();
		ExcelProjectUtils eu = new ExcelProjectUtils();
		eu.exportExcel(rr, out);   //<1>
		ConvertUtil cu = new ConvertUtil();
		try {
			ByteArrayInputStream byteInput = cu.parse(out);
			String rs = PicUploadToYun.uploadExcel(SysContent.getFileRename("案场数据报.xls"), byteInput);  //<2>
			addReportExcelToDB(rr, rs);  //<3>
			return true;
		} catch (Exception e) {
			e.printStackTrace();
		}

		return false;
	}
```
<1> 将数据生成二进制Excel文件 (方法详细见下面代码)
<2> 将生成的二进制文件上传到腾讯云对象存储服务器 (方法详细见下面代码)
<3> 将服务器返回的url存储到数据库 (方法详细见下面代码)


```java
/**
	 * 周报年报生成excel
	 * 
	 * @param report
	 * @param out
	 */
	public void exportExcel(ReportResult report, OutputStream out) {

		// 判断传入的时间间隔
		String dateStr = "";
		String reportName = "";
		List<String> dateCount = DateUtil.getTwoDateEveryDay(report.getStartTime(), report.getEndTime());
		if (dateCount.size() <= 7) {
			dateStr += "本周";
			reportName += "案场周报";
		} else if (dateCount.size() >= 28 && dateCount.size() <= 31) {
			dateStr += "本月";
			reportName += "案场月报";
		} else if (dateCount.size() >= 85 && dateCount.size() <= 100) {
			dateStr += "本季度";
			reportName += "案场季报";
		} else if (dateCount.size() >= 180 && dateCount.size() <= 185) {
			dateStr += "本半年度";
			reportName += "案场半年报";
		} else if (dateCount.size() >= 360 && dateCount.size() <= 367) {
			dateStr += "本年度";
			reportName += "案场年报";
		} else {
			dateStr += "时间段内";
			reportName += "案场阶段报";
		}
		report.setReportName(reportName);
		// 声明一个工作薄
		HSSFWorkbook workbook = new HSSFWorkbook();
		// 生成一个表格
		HSSFSheet sheet = workbook.createSheet(report.getReportName() + report.getStartTime() + " - " + report.getEndTime());
		// 设置表格默认列宽度为100个字节
		sheet.setDefaultColumnWidth((short) 100);
		/** ----------样式一：标题 ------------ **/
		HSSFCellStyle style = workbook.createCellStyle();
		// 设置这些样式
		style.setBorderLeft(HSSFCellStyle.BORDER_THIN);
		style.setBorderRight(HSSFCellStyle.BORDER_THIN);
		//style.setBorderTop(HSSFCellStyle.BORDER_THIN);
		style.setAlignment(HSSFCellStyle.ALIGN_CENTER);
		// 生成一个字体
		HSSFFont font = workbook.createFont();
		font.setFontName("宋体");
		//font.setColor(HSSFColor.VIOLET.index);
		font.setFontHeightInPoints((short) 14);
		font.setBoldweight(HSSFFont.BOLDWEIGHT_BOLD);
		// 把字体应用到当前的样式
		style.setFont(font);
		/***---------样式二：小标题---------***/
		HSSFCellStyle style2 = workbook.createCellStyle();
		style2.setBorderLeft(HSSFCellStyle.BORDER_THIN);
		style2.setBorderRight(HSSFCellStyle.BORDER_THIN);
		//style2.setBorderTop(HSSFCellStyle.BORDER_THIN);
		style2.setAlignment(HSSFCellStyle.ALIGN_LEFT);
		
		//style2.setVerticalAlignment(HSSFCellStyle.VERTICAL_CENTER);
		// 生成另一个字体
		HSSFFont font2 = workbook.createFont();
		//font2.setBoldweight(HSSFFont.BOLDWEIGHT_NORMAL);
		font2.setFontName("宋体");
		font2.setFontHeightInPoints((short) 11);
		font2.setBoldweight(HSSFFont.BOLDWEIGHT_BOLD);
		// 把字体应用到当前的样式
		style2.setFont(font2);
		
		/***    样式三：右侧日期       ***/
		HSSFCellStyle style3 = workbook.createCellStyle();
		//样式
		style3.setBorderLeft(HSSFCellStyle.BORDER_THIN);
		style3.setBorderRight(HSSFCellStyle.BORDER_THIN);
		style3.setAlignment(HSSFCellStyle.ALIGN_RIGHT);
		style3.setBorderBottom(HSSFCellStyle.BORDER_THIN);
		//字体
		HSSFFont font3 = workbook.createFont();
		font3.setFontName("宋体");
		font3.setFontHeightInPoints((short) 11);
		style3.setFont(font3);
		
		/**       样式四：主内容        ***/
		HSSFCellStyle style4 = workbook.createCellStyle();
		//样式
		style4.setBorderLeft(HSSFCellStyle.BORDER_THIN);
		style4.setBorderRight(HSSFCellStyle.BORDER_THIN);
		style4.setAlignment(HSSFCellStyle.ALIGN_LEFT);
		//字体
		HSSFFont font4 = workbook.createFont();
		font4.setFontName("宋体");
		font4.setFontHeightInPoints((short) 11);
		style4.setFont(font4);
		
		/**       样式五：底侧空内容       ***/
		HSSFCellStyle style5 = workbook.createCellStyle();
		//样式
		style5.setBorderLeft(HSSFCellStyle.BORDER_THIN);
		style5.setBorderRight(HSSFCellStyle.BORDER_THIN);
		style5.setAlignment(HSSFCellStyle.ALIGN_LEFT);
		style5.setBorderBottom(HSSFCellStyle.BORDER_THIN);
		//字体
		HSSFFont font5 = workbook.createFont();
		font5.setFontName("宋体");
		font5.setFontHeightInPoints((short) 11);
		style5.setFont(font5);
		
		
		// 声明一个画图的顶级管理器
		HSSFPatriarch patriarch = sheet.createDrawingPatriarch();
		// 定义注释的大小和位置,详见文档
		HSSFComment comment = patriarch.createComment(new HSSFClientAnchor(0, 0, 0, 0, (short) 4, 2, (short) 6, 5));
		// 设置注释内容
		comment.setString(new HSSFRichTextString("数据报"));
		// 设置注释作者，当鼠标移动到单元格上是可以在状态栏中看到该内容.
		comment.setAuthor("saas");

		// 产生表格标题行 -- 项目名称
		HSSFRow row = sheet.createRow(0);
		createCellAndRow(style4, report.getProjectName(), row);

		// 产生表格标题行 -- 周报名称
		row = sheet.createRow(1);
		createCellAndRow(style, report.getReportName(), row);

		// 产生表格标题行 -- 起始时间-终止时间
		row = sheet.createRow(2);
		String startTime = DateUtil.format(DateUtil.parse(report.getStartTime(), DateUtil.PATTERN_CLASSICAL_SIMPLE),
				DateUtil.PATTERN_CLASSICAL_SIMPLE_YMD);
		String endTime = DateUtil.format(DateUtil.parse(report.getEndTime(), DateUtil.PATTERN_CLASSICAL_SIMPLE),
				DateUtil.PATTERN_CLASSICAL_SIMPLE_YMD);
		String date = "日期：" + startTime + " - " + endTime;
		createCellAndRow(style3, date, row);

		// 接访情况标题
		row = sheet.createRow(3);
		createCellAndRow(style2, "·接访情况", row);

		// 接访客户组数
		row = sheet.createRow(4);
		Integer visitCount = report.getVisitCount();
		String visitNum = "1、" + dateStr + "共计接访客户" + visitCount + "组，来访量";
		if (visitCount < 40) {
			visitNum += "较少，有待提升";
		} else if (visitCount >= 41 && visitCount <= 99) {
			visitNum += "尚可，还有提高空间";
		} else if (visitCount >= 100 && visitCount <= 139) {
			visitNum += "很多";
		} else if (visitCount > 140) {
			visitNum += "火爆";
		}
		createCellAndRow(style4, visitNum, row);

		// 有效接访率
		row = sheet.createRow(5);
		Double visitRate = new Double(report.getValidVisitRate());
		String visitRateStr = "2、有效接访率为" + visitRate + "%，接访成效";
		if (visitRate < 50) {
			visitRateStr += "较低，有待提升";
		} else if (visitRate >= 50 && visitRate <= 65) {
			visitRateStr += "尚可，还有提高空间";
		} else if (visitRate >= 65 && visitRate <= 80) {
			visitRateStr += "很高";
		} else if (visitRate > 80) {
			visitRateStr += "极高";
		}
		createCellAndRow(style4, visitRateStr, row);

		// 首访有效率
		row = sheet.createRow(6);
		Double newVisitRate = new Double(report.getValidNewCuVisitRate());
		String newVisitStr = "3、首访有效率为" + newVisitRate + "%，来访转储客的概率";
		if (newVisitRate < 40) {
			newVisitStr += "较差，有待提升";
		} else if (newVisitRate >= 40 && newVisitRate <= 60) {
			newVisitStr += "尚可，还有提高空间";
		} else if (newVisitRate >= 60 && newVisitRate <= 75) {
			newVisitStr += "很高";
		} else if (newVisitRate > 75) {
			newVisitStr += "极高";
		}
		createCellAndRow(style4, newVisitStr, row);

		// 老客户接访占比
		row = sheet.createRow(7);
		Double oldVisitRate = new Double(report.getOldCuVisitRate());
		String oldVisitStr = "4、老客户接访比为" + oldVisitRate + "%，老客户接访的占比";
		if (oldVisitRate < 20) {
			oldVisitStr += "较低";
		} else if (oldVisitRate >= 20 && oldVisitRate <= 40) {
			oldVisitStr += "尚可";
		} else if (oldVisitRate >= 40 && oldVisitRate <= 60) {
			oldVisitStr += "很高";
		} else if (oldVisitRate > 60) {
			oldVisitStr += "极高";
		}
		createCellAndRow(style4, oldVisitStr, row);

		//空行
		row = sheet.createRow(8);
		createCellAndRow(style4, "", row);
		
		// 储客情况
		row = sheet.createRow(9);
		createCellAndRow(style2, "·储客情况", row);

		// 新增储客
		row = sheet.createRow(10);
		Integer newCuCount = report.getNewCuCount();
		String newCuStr = "1、" + dateStr + "新增储客" + newCuCount + "组，新增量";
		if (newCuCount < 30) {
			newCuStr += "较少，有待提升";
		} else if (newCuCount >= 31 && newCuCount <= 60) {
			newCuStr += "尚可，还有提高空间";
		} else if (newCuCount >= 61 && newCuCount <= 79) {
			newCuStr += "很多";
		} else if (newCuCount > 80) {
			newCuStr += "爆满";
		}
		createCellAndRow(style4, newCuStr, row);

		// 累计老客户
		row = sheet.createRow(11);
		Integer oldCuCount = report.getTotalOldCuCount();
		Integer totalCuCount = report.getTotalCuCount();
		Double oldCuRate = new Double(SysContent.getTwoNumberForValue(oldCuCount, totalCuCount));
		String oldCuStr = "2、累计老客户总量为" + oldCuCount + "组，老客户占比为" + oldCuRate + "%，显示老客户关注度";
		if (oldCuRate < 15) {
			oldCuStr += "较低，有待提升";
		} else if (oldCuRate >= 15 && oldCuRate <= 25) {
			oldCuStr += "尚可，还有提高空间";
		} else if (oldCuRate >= 25 && oldCuRate <= 40) {
			oldCuStr += "很高";
		} else if (oldCuRate > 40) {
			oldCuStr += "极高";
		}
		createCellAndRow(style4, oldCuStr, row);

		// 累计总储客
		row = sheet.createRow(12);
		String totalOldCuStr = "3、累计总储客" + totalCuCount + "组";
		createCellAndRow(style4, totalOldCuStr, row);

		// 成交情况(周报没有，其他有)
		if (report.getSubscribeHouseCount() != null) {
			
			//空行
			row = sheet.createRow(13);
			createCellAndRow(style4, "", row);
			
			row = sheet.createRow(14);
			createCellAndRow(style2, "·成交情况", row);

			// 新增认购套数
			row = sheet.createRow(15);
			Integer subscribeHouseCount = report.getSubscribeHouseCount();
			Double subscribeHouseRate = new Double(report.getSubscribeHouseRate());
			String subscribeHouseStr = "1、" + dateStr + "新增认购套数" + subscribeHouseCount + "套，较" + dateStr + "同期";
			if (subscribeHouseRate < 0) {
				subscribeHouseStr += "减少";
			} else {
				subscribeHouseStr += "增长";
			}
			subscribeHouseStr += Math.abs(subscribeHouseRate) + "%";
			createCellAndRow(style4, subscribeHouseStr, row);

			// 新增认购金额
			row = sheet.createRow(16);
			Long subscribeMoney = report.getSubscribeMoney();
			Double subscribeMoneyRate = new Double(report.getSubscribeMoneyRate());
			String subscribeMoneyStr = "   新增认购金额" + subscribeMoney + "万元，较" + dateStr + "同期";
			if (subscribeHouseRate < 0) {
				subscribeMoneyStr += "减少";
			} else {
				subscribeMoneyStr += "增长";
			}
			subscribeMoneyStr += Math.abs(subscribeMoneyRate) + "%";
			createCellAndRow(style4, subscribeMoneyStr, row);

			// 新增签约套数
			row = sheet.createRow(17);
			Integer signCount = report.getSignCount();
			Double signRate = new Double(report.getSignRate());
			String signStr = "2、新增签约套数" + signCount + "套,较" + dateStr + "同期";
			if (signRate < 0) {
				signStr += "减少";
			} else {
				signStr += "增长";
			}
			signStr += Math.abs(signRate) + "%";
			createCellAndRow(style4, signStr, row);

			// 新增签约金额
			row = sheet.createRow(18);
			Long signHouseMoney = report.getSignHouseMoney();
			Double signHouseMoneyRate = new Double(report.getSignHouseMoneyRate());
			String signHouseMoneyStr = "   新增签约金额" + signHouseMoney + "万元，较" + dateStr + "同期";
			if (signHouseMoneyRate < 0) {
				signHouseMoneyStr += "减少";
			} else {
				signHouseMoneyStr += "增长";
			}
			signHouseMoneyStr += Math.abs(signHouseMoneyRate) + "%";
			createCellAndRow(style4, signHouseMoneyStr, row);

			// 新接访签约率
			row = sheet.createRow(19);
			Double newCustomerSignedRate = new Double(report.getNewCustomerSignedRate());
			String newCustomerSignedStr = "3、" + dateStr + "新客户接访签约率" + newCustomerSignedRate + "%，接访签约概率";
			if (newCustomerSignedRate < 4) {
				newCustomerSignedStr += "较低，与理想值差距大";
			} else if (newCustomerSignedRate >= 4 && newCustomerSignedRate <= 6) {
				newCustomerSignedStr += "尚可，还有提高空间";
			} else if (newCustomerSignedRate >= 6 && newCustomerSignedRate <= 7) {
				newCustomerSignedStr += "很高";
			} else if (newCustomerSignedRate > 7) {
				newCustomerSignedStr += "非常高";
			}
			createCellAndRow(style4, newCustomerSignedStr, row);

			// 储客签约率
			row = sheet.createRow(20);
			Double momeryCustomerSignedRate = new Double(report.getMomeryCustomerSignedRate());
			String momeryCustomerSignedStr = "4、储客签约率" + momeryCustomerSignedRate + "%，储备客户签约概率";
			if (momeryCustomerSignedRate < 7) {
				momeryCustomerSignedStr += "较低，与理想值差距大";
			} else if (momeryCustomerSignedRate >= 7 && momeryCustomerSignedRate <= 12) {
				momeryCustomerSignedStr += "尚可，还有提高空间";
			} else if (momeryCustomerSignedRate >= 12 && momeryCustomerSignedRate <= 15) {
				momeryCustomerSignedStr += "很高";
			} else if (momeryCustomerSignedRate > 15) {
				momeryCustomerSignedStr += "非常高";
			}
			createCellAndRow(style4, momeryCustomerSignedStr, row);

			// 老客户签约率
			row = sheet.createRow(21);
			Double oldCustomerSignedRate = new Double(report.getOldCustomerSignedRate());
			String oldCustomerSignedStr = "5、老客户签约率为23.2%，高意向客户签约概率";
			if (oldCustomerSignedRate < 25) {
				oldCustomerSignedStr += "较低，与理想值差距大";
			} else if (oldCustomerSignedRate >= 25 && oldCustomerSignedRate <= 35) {
				oldCustomerSignedStr += "尚可，还有提高空间";
			} else if (oldCustomerSignedRate >= 35 && oldCustomerSignedRate <= 50) {
				oldCustomerSignedStr += "很高";
			} else if (oldCustomerSignedRate > 50) {
				oldCustomerSignedStr += "非常高";
			}
			createCellAndRow(style4, oldCustomerSignedStr, row);

			// 认购客户签约率
			row = sheet.createRow(22);
			Double contratCuSignedRate = new Double(report.getContratCuSignedRate());
			String contratCuSignedStr = "6、认购客户签约率为92%，已认购客户签约率";
			if (contratCuSignedRate < 95) {
				contratCuSignedStr += "不高，较多退订或拒签";
			} else if (contratCuSignedRate >= 95 && contratCuSignedRate <= 97) {
				contratCuSignedStr += "尚可，一定数量退订或拒签";
			} else if (contratCuSignedRate >= 97 && contratCuSignedRate <= 99) {
				contratCuSignedStr += "很高";
			} else if (contratCuSignedRate > 99) {
				contratCuSignedStr += "非常高";
			}
			createCellAndRow(style4, contratCuSignedStr, row);

			//空行
			row = sheet.createRow(23);
			createCellAndRow(style4, "", row);
			
			//底侧
			row = sheet.createRow(24);
			createCellAndRow(style5, "", row);
			
		}else{
			row = sheet.createRow(13);
			createCellAndRow(style5, "", row);
		}

		try {
			workbook.write(out);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	private void createCellAndRow(HSSFCellStyle style, String text, HSSFRow row) {
		HSSFCell cell = row.createCell(0);
		cell.setCellStyle(style);
		HSSFRichTextString rs = new HSSFRichTextString(text);
		cell.setCellValue(rs);
	}
```

```java
/**
	 * 上传Excel
	 * @param fileNewName
	 * @param uploadFile
	 * @return
	 */
	public static String uploadExcel(String fileNewName,ByteArrayInputStream uploadFile){
		// 设置用户属性, 包括appid, secretId和SecretKey
				// 这些属性可以通过cos控制台获取(https://console.qcloud.com/cos)
				String version = PropertiesUtil.getValue("version");
					 long appId = "你的appId";
	                 String secretId = "你的secretId ";
	                 String secretKey = "你的secretKey ";
				
				// 设置要操作的bucket
				String bucketName = "root";
				// 初始化客户端配置
				ClientConfig clientConfig = new ClientConfig();
				// 设置bucket所在的区域，比如广州(gz), 天津(tj)
				clientConfig.setRegion("sh");
				// 初始化秘钥信息
				Credentials cred = new Credentials(appId, secretId, secretKey);
				// 初始化cosClient
				COSClient cosClient = new COSClient(clientConfig, cred);
				// 文件操作 //
				// 1. 上传文件(默认不覆盖)
				// 将本地的local_file_1.txt上传到bucket下的根分区下,并命名为sample_file.txt
				// 默认不覆盖, 如果cos上已有文件, 则返回错误
				String cosFilePath = "/report/" + fileNewName;
				
				byte[] localFilePath1 = null;
				try {
					localFilePath1 = ConvertUtil.toByteArray(uploadFile);
				} catch (IOException e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				}
				
				UploadFileRequest uploadFileRequest = new UploadFileRequest(bucketName, cosFilePath, localFilePath1);
				uploadFileRequest.setEnableShaDigest(false);
				String uploadFileRet = cosClient.uploadFile(uploadFileRequest);
				System.out.println("upload file ret:" + uploadFileRet);
				//获取保存路径
				ObjectMapper om = new ObjectMapper();
				HashMap map = new HashMap<>();
				try {
					map = om.readValue(uploadFileRet, HashMap.class);
				} catch (JsonParseException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				} catch (JsonMappingException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
				HashMap<String, String> value = (HashMap<String, String>) map.get("data");
				return value.get("source_url");
				
	}
```

```java
public boolean addReportExcelToDB(ReportResult rr, String url) {
		
		if(StringUtils.isEmpty(url)){
			return false;
		}
		if(rr == null){
			return false;
		}
		
		ProjectReportRecord prr = new ProjectReportRecord();
		prr.setCreateTime(DateUtil.format(new Date()));
		prr.setProjectId(rr.getProjectId());
		prr.setProjectName(rr.getProjectName());
		prr.setStartTime(rr.getStartTime());
		prr.setEndTime(rr.getEndTime());
		prr.setUrl(url);
		String report = "";
		if("案场周报".equals(rr.getReportName())){
			report = "week";
		}else if("案场月报".equals(rr.getReportName())){
			report = "month";
		}else if("案场季报".equals(rr.getReportName())){
			report = "quarter";
		}else if("案场半年报".equals(rr.getReportName())){
			report = "half";
		}else if("案场年报".equals(rr.getReportName())){
			report = "year";
		}else{
			report = "other";
		}
		prr.setReportName(report);
		
		baseDao.save(prr);
		
		return true;
	}
```

### 生成的文件示例

**周报或者其他报告都是后台自动根据时间进行判断的**

**周报**
![这里写图片描述](http://img.blog.csdn.net/20171020105154962?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvV2ludGVyX2NoZW4wMDE=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)


**季报**

![这里写图片描述](http://img.blog.csdn.net/20171020105212669?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvV2ludGVyX2NoZW4wMDE=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)



以上