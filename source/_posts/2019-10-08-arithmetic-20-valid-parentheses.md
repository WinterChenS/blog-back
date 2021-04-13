---
layout: post
title: 每日一道算法题-有效的括号
date: 2019-10-08 18:35
comments: true
tags: [算法]
brief: [算法]
reward: true
categories: 算法
keywords: 算法
cover: https://gitee.com/winter_chen/img/raw/master/blog/20210413112931.jpeg
image: https://gitee.com/winter_chen/img/raw/master/blog/20210413112931.jpeg
---

### 题目描述

给定一个只包括 `'('，')'，'{'，'}'，'['，']'` 的字符串，判断字符串是否有效。

有效字符串需满足：

    左括号必须用相同类型的右括号闭合。
    左括号必须以正确的顺序闭合。

注意空字符串可被认为是有效字符串。

示例 1:
```
输入: "()"
输出: true
```
示例 2:
```
输入: "()[]{}"
输出: true
```
示例 3:
```
输入: "(]"
输出: false
```
示例 4:
```
输入: "([)]"
输出: false
```
示例 5:
```
输入: "{[]}"
输出: true
```

### 解题思路

* 使用stack
* 遍历字符串
* 如果当前字符为左半边括号是，则将其压入栈中
* 如果是右括号时，分类讨论：
    * 如栈不为空且为对应的左半边括号，则取出栈顶元素，继续循环
    * 若此时栈为空，则直接返回false
    * 若不为对应的左半边括号，返回false


![图解](https://gitee.com/winter_chen/img/raw/master/blog/20210413114847.gif)

### 示例代码

#### java

```java
public static boolean isValid(String s){
        if (!StringUtils.hasText(s)) return false;
        Stack<Character> stack = new Stack<>();//定义一个stack
        char[] chars = s.toCharArray();
        Map<Character, Character> map = new HashMap<>();//hash表
        map.put('(',')');
        map.put('[',']');
        map.put('{','}');
        for (char aChar : chars) {
            // 如果是左半边括号，则压入栈
            if (map.containsKey(aChar)){
                stack.push(aChar);
            } else {// 不是左半边括号
                // 只有栈中有左半边才有效
                if (stack.size() != 0){
                    // 出栈
                    Character pop = stack.pop();
                    // 如果右半边与左半边无法对应则返回false
                    if (!map.get(pop).equals(aChar)){
                        return false;
                    }else {// 继续循环
                        continue;
                    }
                }else {
                    return false;
                }
            }
        }
        // 左半边括号全部出栈表示两边对应上
        return stack.isEmpty();
    }
```

#### js

```js

var isValid = function(s) {
    let valid = true;
    const stack = [];
    const mapper = {
        '{': "}",
        "[": "]",
        "(": ")"
    }
    
    for(let i in s) {
        const v = s[i];
        if (['(', '[', '{'].indexOf(v) > -1) {
            stack.push(v);
        } else {
            const peak = stack.pop();
            if (v !== mapper[peak]) {
                return false;
            }
        }
    }

    if (stack.length > 0) return false;

    return valid;
};
```

#### python

```python
 class Solution:
        def isValid(self,s):
          stack = []
          map = {
            "{":"}",
            "[":"]",
            "(":")"
          }
          for x in s:
            if x in map:
              stack.append(map[x])
            else:
              if len(stack)!=0:
                top_element = stack.pop()
                if x != top_element:
                  return False
                else:
                  continue
              else:
                return False
          return len(stack) == 0
```

### 扩展

以上的代码只能针对左右完全对应上，并且中间不能出现任何字符，所以这里我想拓展一下，就像代码中一样，括号能对应上并且中间有代码；

```java
public static boolean isValid(String s){
        if (!StringUtils.hasText(s)) return false;
        Stack<Character> stack = new Stack<>();
        char[] chars = s.toCharArray();
        Map<Character, Character> map = new HashMap<>();
        map.put('(',')');
        map.put('[',']');
        map.put('{','}');
        for (char aChar : chars) {
            if (map.containsKey(aChar)){
                stack.push(aChar);
            } else {
                if (stack.size() != 0 && map.containsValue(aChar)){
                    Character pop = stack.pop();
                    if (!map.get(pop).equals(aChar)){
                        return false;
                    }else {
                        continue;
                    }
                }
            }
        }
        return stack.isEmpty();
    }
```

输入：

```
"{[(234)]}"
```

输出：

```
true
```