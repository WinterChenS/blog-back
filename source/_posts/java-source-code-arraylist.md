---
layout: post
title: Java源码之旅(1) - ArrayList
date:  2018-05-26 09:45
comments: true
tags: [java源码]
brief: "java"
reward: true
categories: java源码
keywords: java
cover: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046773158786.jpg
image: https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046773390686.jpg
---

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046773582634.jpg)

>  技术在学习中成长，源码的世界没有你想象的那么复杂
<!-- more -->
## 前言

2018年的五月，开始java的源码学习之旅，从简单的角度去理解java的源码，前几天在学习交流中正好看了一下java集合的源码，才发现源码并没有想象中的那么难以理解，所以，源码之旅从java的集合类开始咯。

本章的源码版本为：`JDK1.8`

## 类的关系

要理解`ArrayList`的源码，我们就需要从它的关系开始，`ArrayList`继承了`AbstractList`，实现了`List`接口，我们从UML图可以看出：

![](https://cdn.jsdelivr.net/gh/WinterChenS/img/posts/1628046462618337.png)

虚线箭头表示实现接口，实线箭头表示继承关系

## ArrayList简介

`ArrayList`是`java`中最常用的集合类了，说到`ArrayList`，我们不得不说说`LinkedList`，因为他们都是从`Collection`派生而来的，都是用来存放对象的序列的集合类，`ArrayList`相比与`LinkedList`有什么优劣呢？

- `ArrayList`:

  - 优点：**随机访问元素的速度快**

  - 缺点：**从中间插入和移除元素比较慢**

- `LinkedList`：

  - 优点：**从中间插入和移除元素速度快**

  - 缺点：**随机访问元素的速度比较慢**

接下来我们就从源码的角度去理解一下为什么有这些优缺点。

## 源码分析

### ArrayList的初始化

`ArrayList`有三个构造方法

```java
//默认初始容量
private static final int DEFAULT_CAPACITY = 10;
//空的元素数组
private static final Object[] EMPTY_ELEMENTDATA = {};
//初始容量空的元素数组
private static final Object[] DEFAULTCAPACITY_EMPTY_ELEMENTDATA = {};
// 存放元素的数组
transient Object[] elementData; // non-private to simplify nested class access
//数组的大小
private int size;

// 空参的构造方法
public ArrayList() {
        this.elementData = DEFAULTCAPACITY_EMPTY_ELEMENTDATA; // -- (1)
    }

//指定初始容量的构造方法
public ArrayList(int initialCapacity) {
        if (initialCapacity > 0) {
            this.elementData = new Object[initialCapacity]; // -- (2)
        } else if (initialCapacity == 0) {
            this.elementData = EMPTY_ELEMENTDATA; // -- (3)
        } else {
            throw new IllegalArgumentException("Illegal Capacity: "+
                                               initialCapacity);
        }
    }

//初始化给定一个集合的构造函数
public ArrayList(Collection<? extends E> c) {
        elementData = c.toArray();    // -- (4)
        if ((size = elementData.length) != 0) {
            // c.toArray might (incorrectly) not return Object[] (see 6260652)
            if (elementData.getClass() != Object[].class)
                elementData = Arrays.copyOf(elementData, size, Object[].class);  // -- (5)
        } else {
            // replace with empty array.
            this.elementData = EMPTY_ELEMENTDATA;
        }
    }
```

从源码中我们可以看出，`ArrayList`其实底层使用的是`数组`，`transient Object[] elementData` 这个变量就是用来存放对象的一个数组。

- `ArrayList`的空参构造函数：也就是默认的构造函数，当`new ArrayList()`的时候调用这个方法，可以看出将`elementData`变量地址指向了`DEFAULTCAPACITY_EMPTY_ELEMENTDATA`这个**初始容量为10，并且为空的元素数组**;如步骤`(1)`

- `ArrayList`的指定大小的构造函数：当初始化一个指定大小的`new ArrayList(int)`的时候调用该方法，这个方法首先对`initialCapacity`参数进行判断，**如果大于0**，那么创建一个指定大小的数组`(2)`；**如果等于0**,创建一个空的数组`(3)`；否则就判处异常；

- 初始化给定一个集合的构造函数：如果初始化的时候，给定一个集合对象，那么将这个集合转换为数组 `(4)`，然后对这个数组的长度进行判断，如果数组不等于0，那么调用`Arrays.copyOf(elementData, size, Object[].class)`方法`(5)`，这个方法是一个**核心方法**，这个方法就是初始化一个大小为等于当前数组的一个新的数组，然后将对象`copy`到新的数组中，然后将内存地址指定给`elementData`，从下面的`Arrays.copyOf`的源码可以看出来。

```java
public static <T,U> T[] copyOf(U[] original, int newLength, Class<? extends T[]> newType) {
        @SuppressWarnings("unchecked")
        T[] copy = ((Object)newType == (Object)Object[].class)
            ? (T[]) new Object[newLength]
            : (T[]) Array.newInstance(newType.getComponentType(), newLength);
        System.arraycopy(original, 0, copy, 0,
                         Math.min(original.length, newLength));
        return copy;
    }
```

`copyOf`方法首先判断两个对象的类型，如果类型一致，那么直接创建一个同大小的数组；如果类型不一致，则调用`Array.newInstance`指定类型进行初始化这个数组，当然，大小也是一致的; 最后调用`System.arraycopy`将参数数组`copy`到新的目标并返回。

### ArrayList的常用方法之 add

我们先看一下源码：

```java
public boolean add(E e) {
        ensureCapacityInternal(size + 1);  // Increments modCount!! -- (1)
        elementData[size++] = e;
        return true;
    }

public void add(int index, E element) {
        rangeCheckForAdd(index);//-- (2)

        ensureCapacityInternal(size + 1);  // Increments modCount!!
        System.arraycopy(elementData, index, elementData, index + 1,
                         size - index); //-- (3)
        elementData[index] = element;
        size++;
    }
```

ArrayList有两个add方法，第一个方法就是按顺序将对象插入到尾部，第二个方法就是从中间插入对象。

`add(E e)` 方法首先会判断数组的容量是否超过极限`ensureCapacityInternal(size + 1)`，这个方法首先会进行容量的判断，如果超过了极限，创建一个新的数组，大小是旧数组1.5倍，然后将旧数组中的对象全部拷贝到新的数组`(1)`，等下会详细解析这个方法。最后将参数对象插入到数组中，返回true。

`add(int index, E element)`首先会调用`rangeCheckForAdd(index)`进行index的是否越界的验证`(2)`，然后调用上一个方法中一样的判断容量是否超过极限的方法，下一步就是一个核心的方法`System.arraycopy`，这个方法我们在`ArrayList初始化中`已经讲过了，但是这里不太一样：

- `elementData` : 源数组

- `index`：源数组起始位置

- `elementData`：目标数组

- `index + 1`：目标数组起始位置

- `size - index`：复制数组元素数目

从源码中可以看出，当我们往一个ArrayList中间插入一个对象的时候，index索引处后面的索引往后移动一位，最后把索引为index空出来，并将element赋值给它。这样一来我们并不知道要插入哪个位置，所以会进行匹配那么它的时间赋值度就为n。

接下来看一下`ensureCapacityInternal(size + 1)`这个方法的调用链：

```java
private void ensureCapacityInternal(int minCapacity) {
  if (elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA) {
    minCapacity = Math.max(DEFAULT_CAPACITY, minCapacity);
  }

  ensureExplicitCapacity(minCapacity);
}


private void ensureExplicitCapacity(int minCapacity) {
  modCount++;

  // overflow-conscious code
  if (minCapacity - elementData.length > 0)
    grow(minCapacity);
}

private void grow(int minCapacity) {
  // overflow-conscious code
  int oldCapacity = elementData.length;
  int newCapacity = oldCapacity + (oldCapacity >> 1);//oldCapacity >> 1 就是除以2
  if (newCapacity - minCapacity < 0)
    newCapacity = minCapacity;
  if (newCapacity - MAX_ARRAY_SIZE > 0)
    newCapacity = hugeCapacity(minCapacity);
  // minCapacity is usually close to size, so this is a win:
  elementData = Arrays.copyOf(elementData, newCapacity);
}
```

`ensureCapacityInternal(int minCapacity)`方法中判断当前数组中的元素是否为空，如果为空则给定一个最大的值，然后调用`ensureExplicitCapacity(minCapacity)`，这个方法主要是判数组容量是否超过极限，如果超过极限调用`grow(int minCapacity)`，这个方法就是扩容方法，该方法会创建一个比原数组大1.5倍的新数组，然后将原数组中的所有对象`copy`到新的数组中。



### ArrayList的常用方法之 remove

`remove`方法其实跟从中间插入对象的`add`方法有很大的相似之处，如果我们删除某一个元素，将`index`开始后面的所有对象都往前移动一位，底层方法其实是复制一遍，所以删除一个对象的复杂度和从中间插入一个对象是差不多的。

```java
public E remove(int index) {
        rangeCheck(index);

        modCount++;
        E oldValue = elementData(index);

        int numMoved = size - index - 1;
        if (numMoved > 0)
            System.arraycopy(elementData, index+1, elementData, index,
                             numMoved);
        elementData[--size] = null; // clear to let GC do its work

        return oldValue;
    }
```

### ArrayList的常用方法之 get

`ArrayList`的`get`方法非常直观的就能理解了，废话不多说，直接看代码:

```java
 public E get(int index) {
   rangeCheck(index);

   return elementData(index);
 }
```

检查index合法性，然后从数组中取出对象并返回，是不是很简单呢？





## 总结

本章列举了一些ArrayList常用的方法，了解到ArrayList底层其实是一个对象数组，以及从中间插入对象和移除对象比较慢的原因，从这些方法出发，理解ArrayList其他的方法会很简单了。下一章讲一讲LinkedList的源码。


