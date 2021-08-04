---
layout: post
title: Hibernate 自定义查询sql 并使用自定义对象接收查询结果
date:  2018-01-18 21:50
comments: true
tags: [Hibernate]
brief: "Hibernate"
reward: true
categories: Hibernate
keywords: Hibernate
cover: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039838.jpg
image: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039838.jpg
---
![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628039838.jpg)
> 在很多的生产中，hibernate并不能满足我们所有的开发需求，比如，很多表的联合查询，并且查询之后的各种结果封装在自定义的dto对象中，那么我们就需要使用自定义的sql进行查询了，好了，开始我们新的旅程吧。
<!--  more  -->
### 需求：
* n张表进行联合查询
* 将结果封装在一个DTO的对象中

### 代码：
**本文中使用了一个很复杂的联合查询的sql，所以大家并不需要了解详细，只需要只是我们进行一个很复杂的多张表进行联合查询的操作，最后将结果使用自定义的dto对象接收即可**

#### SQL

```sql
SELECT
	p9.projectId,
	p9.fenxiaoMoney,
	p9.shopCount
FROM
	(
		SELECT
			p8.projectId,
			p8.fenxiaoMoney,
			count(ic.inviteByPerson) shopCount
		FROM
		(
			SELECT
				p7.projectId,
				p7.fenxiaoMoney
			FROM
				(
					SELECT
						pp.projectId,
						g.fenxiaoMoney
					FROM
						(
							SELECT
								p6.projectId
							FROM
								(
									SELECT
										p5.projectId
									FROM
										(
											SELECT
												p4.projectId
											FROM
												(
													SELECT
														p2.projectId
													FROM
														(
															SELECT
																p1.projectId
															FROM
																(
																	SELECT
																		p.projectId
																	FROM
																		t_projects p
																	WHERE
																		1 = 1
																	AND p.averagePrice >= 1.0
																	AND p.averagePrice <= 10000000000.0
																	AND p.saleLongitude >= 1.0
																	AND p.saleLongitude <= 10000.00
																	AND p.saleLatitude >= 1.0
																	AND p.saleLatitude <= 10000.0
																	AND p.rightsYears = 70
																	AND p.city LIKE '%330000%' #AND p.isOpenStatus = 1
																	AND p.buildArea >= 1.0
																	AND p.buildArea <= 10000000.0 #AND p.afforestationRatio = 1
																	AND p.projectName LIKE '%%' #AND p.projectId = '1515269bc87448b4927fa676c624c8f6'
																) p1
															INNER JOIN (
																SELECT
																	targetId
																FROM
																	t_tagsrelation
																WHERE
																	1 = 1
																AND originalTags LIKE '%4507%'
																AND originalTags LIKE '%757%'
															) t1 ON p1.projectId = t1.targetId
														) p2
													INNER JOIN (
														SELECT
															h.projectId
														FROM
															t_projecthouses h
														WHERE
															h.houseNum IN (
																SELECT
																	targetId
																FROM
																	t_tagsrelation
																WHERE
																	1 = 1
																AND originalTags LIKE '%%'
															)
														AND h.houseStatus = 1
														AND isOpen = 1
													) p3 ON p2.projectId = p3.projectId
												) p4
											INNER JOIN (
												SELECT
													projectId
												FROM
													t_projecthousetypes pht
												WHERE
													1 = 1
												AND pht.housType = '三房两厅一卫'
											) pht1 ON p4.projectId = pht1.projectId
											GROUP BY
												p4.projectId
										) p5
									INNER JOIN (
										SELECT
											ph.projectId
										FROM
											t_projecthouses ph
										WHERE
											1 = 1
										AND (
											ph.houseKind = '10'
											OR ph.houseKind = '0'
										)
									) hk ON p5.projectId = hk.projectId
									GROUP BY
										p5.projectId
								) p6
							INNER JOIN (
								SELECT
									applyForPerson
								FROM
									t_applychart
								WHERE
									applyByPerson = '860635'
								AND applyStatus = 2
							) ap ON p6.projectId = ap.applyForPerson
						) pp
					LEFT JOIN t_projectguide g ON pp.projectId = g.projectId
				) p7
		) p8
			
		LEFT JOIN (SELECT inviteByPerson FROM t_invitechart WHERE inviteStatus = 2) ic ON p8.projectId = ic.inviteByPerson
		GROUP BY
			p8.projectId
	) p9
LEFT JOIN (
	SELECT
		beCollectId
	FROM
		t_newcollectrecord
	WHERE
		userId = '4e0b0089-410a-497e-8056-6190e2a183d4'
) nc ON p9.projectId = nc.beCollectId
GROUP BY
	p9.projectId
ORDER BY
	shopCount DESC
LIMIT 0,
 10
```

从sql中可以看出我们需要查的三个参数：

*  项目的Id
*  钱的数量
*  合作店铺的数量

需要的额外功能：

*  分页
*  根据上面的参数进行排序

#### SQL拼接方法

**顾名思义就是将上述的sql使用java进行拼接，因为这样便于查看和bug查找(这段并不重要)**
```java
/**
	 * 拼接Hql中的p段
	 * @param param
	 * @param user
	 * @param sb
	 */
	private void jointHqlTheP(ShopSearchParam param, User user, StringBuilder sb){
		/**
		 * SELECT
				p.projectId
			FROM
				t_projects p
			WHERE
				1 = 1
			AND p.averagePrice >= 1.0
			AND p.averagePrice <= 10000000000.0
			AND p.saleLongitude >= 1.0
			AND p.saleLongitude <= 10000.00
			AND p.saleLatitude >= 1.0
			AND p.saleLatitude <= 10000.0
			AND p.rightsYears = 70
			AND p.city LIKE '%330000%' #AND p.isOpenStatus = 1
			AND p.buildArea >= 1.0
			AND p.buildArea <= 10000000.0 #AND p.afforestationRatio = 1
			AND p.projectName LIKE '%%' #AND p.projectId = '1515269bc87448b4927fa676c624c8f6'
		 */
		
		sb.append(" SELECT ");
		sb.append(" p.projectId ");
		sb.append(" FROM ");
		sb.append(" t_projects p ");
		sb.append(" WHERE ");
		sb.append(" 1 = 1 ");
		if(param.getMinAveragePrice() != null){
			sb.append(" AND p.averagePrice >= " + param.getMinAveragePrice());
		}
		if(param.getMaxAveragePrice() != null){
			sb.append(" AND p.averagePrice <= " + param.getMaxAveragePrice());
		}
		if(!isEmpty(param.getMinLongitudes())){
			sb.append(" AND p.saleLongitude >= " + param.getMinLongitudes());
		}
		if(!isEmpty(param.getMaxLongitudes())){
			sb.append(" AND p.saleLongitude <= " + param.getMaxLongitudes());
		}
		if(!isEmpty(param.getMinLatitudes())){
			sb.append(" AND p.saleLatitude >= " + param.getMinLatitudes());
		}
		if(!isEmpty(param.getMaxLatitudes())){
			sb.append(" AND p.saleLatitude <= " + param.getMaxLatitudes());
		}
		if(param.getRightsYears() != null){
			sb.append(" AND p.rightsYears = " + param.getRightsYears());
		}
		if(!isEmpty(param.getCityId())){
			sb.append(" AND p.city LIKE '%" + param.getCityId() + "%'");
		}else if(!isEmpty(param.getCityName())){
			String hql = "from CountryProvinceInfo where cityName = '" + param.getCityName() + "' and cityLevel = '市' ";
			CountryProvinceInfo cp = (CountryProvinceInfo) baseDao.loadObject(hql);
			String cityId = cp.getUpCityId();
			sb.append(" AND p.city LIKE '%" + cityId + "%'");
		}
		//项目状态 在售、等待售、全部
		if(param.getProjectStatus() != null){
			
			sb.append(" AND p.isOpenStatus = " + param.getProjectStatus());
		}
		if(param.getMinBulidArea() != null){
			sb.append(" AND p.buildArea >= " + param.getMinBulidArea());
		}
		if(param.getMaxBuildArea() != null){
			sb.append(" AND p.buildArea <= " + param.getMaxBuildArea());
		}
		if(!isEmpty(param.getProjectName())){
			sb.append(" AND p.projectName LIKE '%" + param.getProjectName() + "%' ");
		}
		if(!isEmpty(param.getProjectId())){
			sb.append(" AND p.projectId = '" + param.getProjectId() + "' ");
		}
		
	}
	
	/**
	 * 拼接Hql的p1段 -- 项目标签过滤
	 * @param param
	 * @param user
	 * @param sb
	 */
	private void jointHqlTheP1(ShopSearchParam param, User user, StringBuilder sb){
		/**
		 * SELECT
				p1.projectId
			FROM
				(
					{p}//这个是p段
				) p1
			INNER JOIN (
				SELECT
					targetId
				FROM
					t_tagsrelation
				WHERE
					1 = 1
				AND originalTags LIKE '%4507%'
				AND originalTags LIKE '%757%'
			) t1 ON p1.projectId = t1.targetId
		 */
		sb.append(" SELECT ");
		sb.append(" p1.projectId ");
		sb.append(" FROM ");
		sb.append(" ( ");
		
		this.jointHqlTheP(param, user, sb);//将p加入
		
		sb.append(" ) p1 ");
		if(!isEmpty(param.getpTags())){
			sb.append(" INNER JOIN ( ");
			sb.append(" SELECT ");
			sb.append(" targetId ");
			sb.append(" FROM ");
			sb.append(" t_tagsrelation ");
			sb.append(" WHERE ");
			sb.append(" 1 = 1 ");
			String[] pTags = this.stringToArray(param.getpTags());
			for (int i = 0; i < pTags.length; i++) {
				sb.append(" AND originalTags LIKE '%" + pTags[i] + "%' ");
			}
			sb.append(" ) t1 ON p1.projectId = t1.targetId ");
		}
		
	}
	
	/**
	 * 拼接Hql的p2段 -- 房源标签过滤
	 * @param param
	 * @param user
	 * @param sb
	 */
	private void jointHqlTheP2(ShopSearchParam param, User user, StringBuilder sb){
		/**
		 * SELECT
				p2.projectId
			FROM
				(
					{p1}//这个是p1段
				) p2
			INNER JOIN (
				SELECT
					h.projectId
				FROM
					t_projecthouses h
				WHERE
					h.houseNum IN (
						SELECT
							targetId
						FROM
							t_tagsrelation
						WHERE
							1 = 1
						AND originalTags LIKE '%%'
					)
				AND h.houseStatus = 1
				AND isOpen = 1
			) p3 ON p2.projectId = p3.projectId
		 */
		
		sb.append(" SELECT ");
		sb.append(" p2.projectId ");
		sb.append(" FROM ");
		sb.append(" ( ");
		
		this.jointHqlTheP1(param, user, sb);//这个拼接p1
		
		sb.append(" ) p2 ");
		
		if(!isEmpty(param.gethTags())){
			sb.append(" INNER JOIN ( ");
			sb.append(" SELECT ");
			sb.append(" h.projectId ");
			sb.append(" FROM ");
			sb.append(" t_projecthouses h ");
			sb.append(" WHERE ");
			sb.append(" h.houseNum IN ( ");
			sb.append(" SELECT ");
			sb.append(" targetId ");
			sb.append(" FROM ");
			sb.append(" t_tagsrelation ");
			sb.append(" WHERE ");
			sb.append(" 1=1 ");
			String[] hTags = this.stringToArray(param.gethTags());
			for (int i = 0; i < hTags.length; i++) {
				sb.append(" AND originalTags LIKE '%" + hTags[i] + "%' ");
			}
			sb.append(" ) ");
			sb.append(" AND h.houseStatus = 1 ");
			sb.append(" AND isOpen = 1 ");
			sb.append(" ) p3 ON p2.projectId = p3.projectId ");
			
		}
	}
	
	/**
	 * 拼接Hql的p4段 -- 房源户型
	 * @param param
	 * @param user
	 * @param sb
	 */
	private void jointHqlTheP4(ShopSearchParam param, User user, StringBuilder sb){
		/**
		 * SELECT
				p4.projectId
			FROM
				(
					{p2}//这个是p2段
				) p4
			INNER JOIN (
				SELECT
					projectId
				FROM
					t_projecthousetypes pht
				WHERE
					1 = 1
				AND pht.housType = '三房两厅一卫'
			) pht1 ON p4.projectId = pht1.projectId
			GROUP BY
				p4.projectId
		 */
		sb.append(" SELECT ");
		sb.append(" p4.projectId ");
		sb.append(" FROM ");
		sb.append(" ( ");
		
		this.jointHqlTheP2(param, user, sb);
		
		sb.append(" ) p4 ");
		
		if(!isEmpty(param.getHouseType())){
			sb.append(" INNER JOIN ( ");
			sb.append(" SELECT ");
			sb.append(" projectId ");
			sb.append(" FROM ");
			sb.append(" t_projecthousetypes pht ");
			sb.append(" WHERE ");
			sb.append(" 1 = 1 ");
			sb.append(" AND pht.housType = '" + param.getHouseType() + "' ");
			sb.append(" ) pht1 ON p4.projectId = pht1.projectId ");
			sb.append(" GROUP BY ");
			sb.append(" p4.projectId ");
		}
		
		
		
	}
	
	/**
	 * 拼接Hql的p5段 -- 房源类型过滤
	 * @param param
	 * @param user
	 * @param sb
	 */
	private void jointHqlTheP5(ShopSearchParam param, User user, StringBuilder sb){
		/**
		 * SELECT
				p5.projectId
			FROM
				(
					{p4}//拼接p4段
				) p5
			INNER JOIN (
				SELECT
					ph.projectId
				FROM
					t_projecthouses ph
				WHERE
					1 = 1
				AND (
					ph.houseKind = '10'
					OR ph.houseKind = '0'
				)
			) hk ON p5.projectId = hk.projectId
			GROUP BY
				p5.projectId
		 */
		sb.append(" SELECT ");
		sb.append(" p5.projectId ");
		sb.append(" FROM ");
		sb.append(" ( ");
		
		this.jointHqlTheP4(param, user, sb);
		
		sb.append(" ) p5 ");
		
		if(!isEmpty(param.getHouseKinds())){
			sb.append(" INNER JOIN ( ");
			sb.append(" SELECT ");
			sb.append(" ph.projectId ");
			sb.append(" FROM ");
			sb.append(" t_projecthouses ph ");
			sb.append(" WHERE ");
			sb.append(" 1 = 1 ");
			sb.append(" AND ( ");
			String[] kinds = this.stringToArray(param.getHouseKinds());
			for (int i = 0; i < kinds.length; i++) {
				if(i == 0){
					sb.append(" ph.houseKind = '" + kinds[i] + "' ");
				}else{
					sb.append(" OR  ph.houseKind = '" + kinds[i] + "' ");
				}
			}
			sb.append(" ) ");
			sb.append(" ) hk ON p5.projectId = hk.projectId ");
			sb.append(" GROUP BY p5.projectId ");
		}
		
	}
	
	/**
	 * 拼接Hql的p5段 -- 房源类型过滤
	 * @param param
	 * @param user
	 * @param sb
	 */
	private void jointHqlTheP6(ShopSearchParam param, User user, StringBuilder sb){
		/**
		 * SELECT
				p6.projectId
			FROM
				(
					{p5}//拼接p5段
				) p6
			INNER JOIN (
				SELECT
					applyForPerson
				FROM
					t_applychart
				WHERE
					applyByPerson = '860635'
				AND applyStatus = 2
			) ap ON p6.projectId = ap.applyForPerson
		 */
		sb.append(" SELECT ");
		sb.append(" p6.projectId ");
		sb.append(" FROM ");
		sb.append(" ( ");
		this.jointHqlTheP5(param, user, sb);
		sb.append(" ) p6 ");
		
		if(param.getInviteStatus() != null){
			sb.append(" INNER JOIN ( ");
			sb.append(" SELECT ");
			sb.append(" applyForPerson ");
			sb.append(" FROM ");
			sb.append(" t_applychart ");
			sb.append(" WHERE ");
			sb.append(" applyByPerson = '" + user.getParentId() + "' ");
			sb.append(" AND applyStatus = " + param.getInviteStatus());
			sb.append(" ) ap ON p6.projectId = ap.applyForPerson ");
			
		}
		
	}
	
	/**
	 * 拼接Hql的PP段 -- 查看带看业务定义中的佣金
	 * @param param
	 * @param user
	 * @param sb
	 */
	private void jointHqlThePP(ShopSearchParam param, User user, StringBuilder sb){
		/**
		 * SELECT
				pp.projectId,
				g.fenxiaoMoney
			FROM
				(
					{p6}//拼接p6段
				) pp
			LEFT JOIN t_projectguide g ON pp.projectId = g.projectId
		 */
		
		sb.append(" SELECT ");
		sb.append(" pp.projectId, ");
		sb.append(" g.fenxiaoMoney ");
		sb.append(" FROM ");
		sb.append(" ( ");
		
		this.jointHqlTheP6(param, user, sb);
		
		sb.append(" ) pp ");
		sb.append(" LEFT JOIN t_projectguide g ON pp.projectId = g.projectId ");
		
	}
	
	
	/**
	 * 拼接Hql的P7段
	 * @param param
	 * @param user
	 * @param sb
	 */
	private void jointHqlTheP7(ShopSearchParam param, User user, StringBuilder sb){
		/**
		 * SELECT
				p7.projectId,
				p7.fenxiaoMoney
			FROM
				(
					{pp}//拼接pp段
				) p7
		 */
		
		sb.append(" SELECT ");
		sb.append(" p7.projectId, ");
		sb.append(" p7.fenxiaoMoney ");
		sb.append(" FROM ");
		sb.append(" ( ");
		
		this.jointHqlThePP(param, user, sb);
		
		sb.append(" ) p7 ");
	}
	
	
	/**
	 * 拼接Hql的P8段 -- 项目的合作门店数量
	 * @param param
	 * @param user
	 * @param sb
	 */
	private void jointHqlTheP8(ShopSearchParam param, User user, StringBuilder sb){
		/**
		 * SELECT
			p8.projectId,
			p8.fenxiaoMoney,
			count(ic.inviteByPerson) shopCount
		FROM
		(
			{p7} //拼接P7段
		) p8
			
		LEFT JOIN t_invitechart ic ON p8.projectId = ic.inviteByPerson
		GROUP BY
			p8.projectId
		 */
		sb.append(" SELECT ");
		sb.append(" p8.projectId, ");
		sb.append(" p8.fenxiaoMoney, ");
		sb.append(" count(ic.inviteByPerson) shopCount ");
		sb.append(" FROM ");
		sb.append(" ( ");
		
		this.jointHqlTheP7(param, user, sb);
		
		sb.append(" ) p8 ");
		sb.append(" LEFT JOIN (SELECT inviteByPerson FROM t_invitechart WHERE inviteStatus = 2) ic ON p8.projectId = ic.inviteByPerson ");
		sb.append(" GROUP BY p8.projectId ");
	}
	
	/**
	 * 拼接Hql的P9段 -- 个人是否收藏
	 * @param param
	 * @param user
	 * @param sb
	 */
	private void jointHqlTheP9(ShopSearchParam param, User user, StringBuilder sb, Page page){
		
		/**
		 * SELECT
		 	*
			FROM
				(
					{p8}//拼接p8段
				) p9
			LEFT JOIN (
				SELECT
					beCollectId
				FROM
					t_newcollectrecord
				WHERE
					userId = '4e0b0089-410a-497e-8056-6190e2a183d4'
			) nc ON p9.projectId = nc.beCollectId
			GROUP BY
				p9.projectId
			ORDER BY
				shopCount DESC
			LIMIT 0,
			 10
		 */
		
		sb.append(" SELECT ");
		sb.append(" p9.projectId, p9.fenxiaoMoney, p9.shopCount ");
		sb.append(" FROM ");
		sb.append(" ( ");
		
		this.jointHqlTheP8(param, user, sb);
		
		sb.append(" ) p9 ");
		if(param.getIsClikeLike() != null){
			sb.append(" LEFT JOIN ( ");
			sb.append(" SELECT ");
			sb.append(" beCollectId ");
			sb.append(" FROM ");
			sb.append(" t_newcollectrecord ");
			sb.append(" WHERE ");
			sb.append(" userId = '" + user.getUserId() + "' ");
			sb.append(" ) nc ON p9.projectId ");
			if(param.getIsClikeLike() == 1){//收藏
				sb.append(" = ");
			}else{//未收藏
				sb.append(" != ");
			}
			sb.append(" nc.beCollectId ");
			
			sb.append(" GROUP BY ");
			sb.append(" p9.projectId ");
		
		}
		
		if(!isEmpty(param.getOrderType()) && param.getOrder() != null){
			
			sb.append(" ORDER BY ");
			if(param.getOrderType().equals(ShopSearchConstant.ORDER_TYPE_SHOP_COUNT)){//合作门店数量
				sb.append(" p9.shopCount ");
			}else if(param.getOrderType().equals(ShopSearchConstant.ORDER_TYPE_MONEY)){//及时结款率  -  暂无
				sb.append(" p9.shopCount ");//暂无，暂时用这个替代
			}else if(param.getOrderType().equals(ShopSearchConstant.ORDER_TYPE_COMMISSION)){//佣金高低
				sb.append(" p9.fenxiaoMoney ");
			}
			sb.append(param.getOrderType());
			if(param.getOrder() == 0){
				sb.append(" DESC ");
			}else{
				sb.append(" ASC ");
			}
		}
		
		if(page != null){
			sb.append(" LIMIT " + page.getStart() + "," + page.getLimit());
		}
		
		 
	}
```

### Service 层
```java
//这个方法是将反射之后得到的字段类型和字段名称进行拆分
private void invokeDtoToFieldsToArray(Field[] fields, String[] colums, String[] types){
		for (int i = 0; i < fields.length; i++) {
			types[i] = fields[i].getType().toString().replace("class java.lang.", "");
			colums[i] = fields[i].getName();
		}
	}
```


**下面的方法就是整个Service中的核心方法了，将自定义sql交给hibernate进行处理，并且使用自定义的dto对象进行封装**
```java
//这个方法就是将sql进行查询
@Override
	public void findProjectListByShopSearchParam(ShopSearchParam shopSearchParam, Page page, User user) {
		StringBuilder sb = new StringBuilder();
		
		// 利用反射获取Project组装类的所有的字段和类型
		Field[] fields = ProjectMapListDTO.class.getDeclaredFields();
		String[] colums = new String[fields.length];
		String[] types = new String[fields.length];
		this.invokeDtoToFieldsToArray(fields, colums, types);
		this.jointHqlTheP9(shopSearchParam, user, sb, page);
		//返回的结果
		List<ProjectMapTotalDTO> rsList = new LinkedList<>();
		//当前用户所有收藏的项目
		List<NewCollectRecord> collList =  this.findNewCollectRecordByUserId(user.getUserId(), ShopSearchConstant.COLLECT_TYPE_PROJECT,null);
		//当前门店所有的申请
		List<ApplyChart> appList = this.findApplyChartsByShopId(user.getParentId(), null);
		//---------重要---------这个就是关键方法
		List<ProjectMapListDTO> list = baseDao.queryDTOBySql(sb.toString(), ProjectMapListDTO.class, colums, types);
		
		//这里是工作需要，将查询出来的结果进行再次封装--看需要吧
		//需要进行判断是否收藏和申请状态的判断
		for (ProjectMapListDTO pd : list) {
			
			ProjectMapTotalDTO ptd = new ProjectMapTotalDTO();
			Project project = (Project) baseDao.loadById(Project.class, pd.getProjectId());
			ptd.setProject(project);
			ptd.setFenxiaoMoney(pd.getFenxiaoMoney());
			ptd.setShopCount(pd.getShopCount());
			//判断是否已经被收藏
			boolean flag = false;
			for(NewCollectRecord nr : collList){
				if(nr.getBeCollectId().equals(pd.getProjectId())){
					flag = true;
				}
			}
			
			//查看合作关系
			for(ApplyChart ac : appList){
				if(pd.getProjectId().equals(ac.getApplyForPerson())){
					ptd.setApplyStatus(ac.getApplyStatus());
				}
			}
			
			ptd.setIsLike(flag ? 1 : 0);
			rsList.add(ptd);
		}
		page.setRoot(rsList);

		List<ProjectMapTotalDTO> lz = this.findProjectListForMapNew(shopSearchParam, user);
		page.setTotal(lz.size());
		
	}
```

看看DTO对象
```java
package com.sc.tradmaster.service.shop.impl.dto;

public class ProjectMapListDTO {

	private String projectId;
	private Double fenxiaoMoney;
	private Integer shopCount;
	
	//省略set和get方法
	

}

```

#### DAO核心方法
```java
public class BaseDaoImpl extends HibernateDaoSupport implements BaseDao{

	@Resource
	public void mySessionFactory(SessionFactory sf){
		super.setSessionFactory(sf);
	}
	
/**
	 * 执行sql组装DTO对象集合
	 * @param sql
	 * @param clazz
	 * @return
	 */
	public List queryDTOBySql(String sql,Class clazz,String[] colums,String[] types) {    
		Session session = super.getSessionFactory().getCurrentSession();
		SQLQuery query = session.createSQLQuery(sql);
		if(colums!=null && types!=null && colums.length==types.length){
			for(int i=0;i<colums.length;i++){
				if(types[i].equals("Integer")){
					query.addScalar(colums[i],StandardBasicTypes.INTEGER);
				}else if(types[i].equals("String")){
					query.addScalar(colums[i],StandardBasicTypes.STRING);
				}else if(types[i].equals("Double")){
					query.addScalar(colums[i],StandardBasicTypes.DOUBLE);
				}else if(types[i].equals("Long")){
					query.addScalar(colums[i],StandardBasicTypes.LONG);
				}
				
			}
		}
		List<Object[]> list = query.setResultTransformer(Transformers.aliasToBean(clazz)).list();
        return list;
    }
   }
```

> 结语：由于是在工作中用到的代码段，所以显得有些复杂化了，以后有时间的话，使用通俗易懂的方法讲解出来，先留个坑，如果大家遇到这种使用场景无法解决的话，欢迎打扰：1085143002@qq.com


