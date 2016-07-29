---
title: 记录一次奇葩的性能调优经历 
date: 2016-07-29 22:23:00
tags: ['性能优化']
description: 几个常用的性能分析工具
keywords:
---

今天在写一个Koa2程序的时候无意间瞥了一眼日志, 发现某个简单的保存表单的API竟然平均耗时 **900ms**, **900ms** 啊同学们! 这种需求
的正常耗时应该是在 **90ms** 以下的

## SQL Profile分析




## 查看硬盘负载

![](http://box-images.qiniudn.com//blog/iostat-1.png)

![](http://box-images.qiniudn.com//blog/iotop-1.png)

![](http://box-images.qiniudn.com//blog/iftop-01.png)

```
$ iostat -d -x -k 1 40

$ iftop -i em2

$ iotop
```

## 解决方法

最后让爬虫的程序爬慢一点, 然后把写磁盘操作也慢一点, insert 语句的速度变有了明显的提升 ([\#还是因为太穷没机器\#](javascript:void))



