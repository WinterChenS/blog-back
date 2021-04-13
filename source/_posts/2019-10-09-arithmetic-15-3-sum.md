---
layout: post
title: 每日一道算法题-三个数的和
date: 2019-10-09 19:03
comments: true
tags: [算法]
brief: [算法]
reward: true
categories: 算法
keywords: 算法
cover: https://gitee.com/winter_chen/img/raw/master/blog/20210413114934.jpg
image: https://gitee.com/winter_chen/img/raw/master/blog/20210413114934.jpg
---

### 题目描述

给定一个包含 n 个整数的数组 nums，判断 nums 中是否存在三个元素 a，b，c ，使得 a + b + c = 0 ？找出所有满足条件且不重复的三元组。

注意：答案中不可以包含重复的三元组。

例如, 给定数组 `nums = [-1, 0, 1, 2, -1, -4]` ，

满足要求的三元组集合为：

```
[
  [-1, 0, 1],
  [-1, -1, 2]
]
```

### 解题思路

如果使用普通算法，那么复杂度为O(n3)，这样的方式效率很低；
我们可以采用*分治*的思想，想要找出三个数相加等于0，我们可以先将nums进行排序，然后依次遍历，每一项nums[i]我们都认为它最终都能够组成0中的一个数字(当然当nums[i]大于0的时候不可能为0)，那么我们的目标就是找到剩下的元素（除a[i]）两个相加等于-a[i]。

通过上面的思路，我们的问题转化为了给定一个数组，找出其中两个相加等于给定值， 这个问题是比较简单的， 我们只需要对数组进行排序，然后双指针解决即可。 加上我们需要外层遍历依次数组，因此总的时间复杂度应该是O(N^2)

![](https://gitee.com/winter_chen/img/raw/master/blog/20210413115018.png)

### 关键

- 排序之后，用双指针
- 分治

### 代码：

```java

public List<List<Integer>> threeSum(int[] nums) {
        List<List<Integer>> resultList = new ArrayList<>();
        if (nums == null || nums.length < 3) return resultList;
        Arrays.sort(nums);//排序
        int len = nums.length;
        for (int i = 0; i < len; i++) {// C位
            if (nums[i] > 0) break;
            if (i > 0 && nums[i] == nums[i - 1]) continue;
            int L = i + 1;
            int R = len - 1;
            while (L < R){
                int sum = nums[i] + nums[L] + nums[R];
                if (sum == 0){
                    resultList.add(Arrays.asList(nums[i], nums[L], nums[R]));
                    while(L < R && nums[L] == nums[L + 1]) L++;
                    while(L < R && nums[R] == nums[R - 1]) R--;
                    L++;
                    R--;
                } else if (sum < 0){
                    L++;
                } else {
                    R--;
                }
            }
        }
            return resultList;
    }
```
