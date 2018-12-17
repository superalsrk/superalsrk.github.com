---
title: PathFilter无法生效
date: 2015-07-15 10:06:42
tags: ['数据开发']
description: 'HDFS中PathFilter无法生效的问题'
keywords: ['PathFilter无法生效', 'Hadoop']
---

最近再写一个MapReduce的时候出现了一个诡异的问题, PathFilter无法生效, 具体描述如下:
1. 代码参考的是另外一个项目(用的是SequenceFileInputFormat),其PathFilter能正常工作
2. 我写的这个MR用的公司的一个CombineFileInputFormat, 虽然设置了Filter但是程序运行的时候PathFilter甚至都没实例化。

<!-- more -->
感觉从PathFilter初始化这个点找应该是个正确的方向,As we all know, `FileInputFormat` 是所有XXFileInputFormat的父类,果然在其中找到了如下代码


```
public abstract class FileInputFormat<K, V> extends InputFormat<K, V>  {

    public List<InputSplit> getSplits(JobContext job) throws IOException {
            //other code
            List<FileStatus> files = listStatus(job);
            //other code
    }

    protected List<FileStatus> listStatus(JobContext job) throws IOException {
            //other code
            Path[] dirs = getInputPaths(job);
            //other code
    }

    public static PathFilter getInputPathFilter(JobContext context) {
       Configuration conf = context.getConfiguration();
       Class<?> filterClass = conf.getClass(PATHFILTER_CLASS, null,
           PathFilter.class);
       return (filterClass != null) ?
           (PathFilter) ReflectionUtils.newInstance(filterClass, conf) : null;
     }
 }

```
这样的话, 只要确保 `getSplits` 方法调用了 `getInputPathFilter`, 那么PathFilter便能初始化成功. 所以实现自定义FileInputFormat
的时候要注意override 方法的实现,先看看CombineFileInputFormat和SequenceFileInputFormat是怎么实现的吧

1. CombineFileInputFormat: 重写了getSplits方法, 但是在重写的方法里调用了 super.listStatus(job), 所以PathFilter正常
2. SequenceFileInputFormat: 重写了listStatus方法, 但是在重写方法里调用了 super.listStatus(job), 所以PathFilter也依然正常
3. 那么再看看自己写的那个InputFormat, 也重写了getSplits方法, 但是获取block status是用 getInputPaths获取路径然后手动获取status的, 根本就没管 父类的listSt方法，因此导致PathFilter失效

这个是一个PathFiter的[Demo](https://gist.github.com/superalsrk/d8a33c5ce56b2bac89ab)

THE END
