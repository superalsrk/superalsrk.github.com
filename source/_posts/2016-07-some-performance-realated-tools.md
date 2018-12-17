---
title: 记录一次奇葩的性能调优经历 
date: 2016-07-29 22:23:00
tags: ['性能优化']
description: 几个常用的性能分析工具
keywords: iostat使用, iotop使用, 机器负载查看
toc: true
---

今天在写一个Koa2程序的时候无意间瞥了一眼日志, 发现某个简单的保存表单的API竟然平均耗时 **900ms**, **900ms** 啊同学们! 这种需求的正常耗时应该再除以10一下

<!-- more -->

## SQL Profile分析

首先需要知道sql语句在哪个阶段慢, mysql提供了profile工具来帮助我们做性能分析:

> MYSQL> set profiling=1
> MYSQL> insert into t_test_table values ('hello')
> MYSQL> show profile for query 1

输入完上面的sql语句后, 会发现主要的耗时是在一个叫 **query end** 的阶段上, [这篇文章](http://inetkiller.github.io/2014/05/20/mysql语句性能分析与优化/)对此阶段的描述如下

> google上得到答案，将mysql的配置文件my.conf里加上一句innodb_flush_log_at_trx_commit = 0。 经过验证，成功解决问题，速度提升非常明显（上面的改动同时对insert操作也起了作用）。 同时留下疑问：query end是什么状态，为什么会用这么久的时间，为什么加上innodb_flush_log_at_trx_commit = 0后性能提升会这么大？

> query end是什么状态？ mysql的官方文档解释是：This state occurs after processing a query but before the freeing items state.我的理解是语句执行完毕了，但是还有一些后续工作没做完时的状态。

> 那么freeing items 又是什么状态呢？ The thread has executed a command. Some freeing of items done during this state involves the query cache. This state is usually followed by cleaning up.就是释放查询缓存里面的空间（因为是update操作，所以相应的缓存里的记录就无效了，所以需要有这一步做处理）。

> innodb_flush_log_at_trx_commit的默认值是1，此时的行为是： the log buffer is written out to the log file at each transaction commit and the flush to disk operation is performed on the log file。log buffer的作用:允许事务在执行完成之后才将日志（事务需要维护一个日志）写到磁盘上，时间主要应该就是耗费在磁盘IO上？

> 而将innodb_flush_log_at_trx_commit的值改为0后，行为如下： If the value of innodb_flush_log_at_trx_commit is 0, the log buffer is written out to the log file once per second and the flush to disk operation is performed on the log file, but nothing is done at a transaction commit。 可以看到，改成0后，本来应该每次提交都进行的操作，变成了每秒钟才进行一次，所以及大的节省了时间。

> 将innodb_flush_log_at_trx_commit的值设置为0有一个副作用：任何服务器端mysql程序的崩溃会导致最后一秒的事务丢失(还没来得及到到日志文件中)。但是考虑到本应用对事务不必有如此严格的要求，所以这是可以接受的。

但是, 这样直接该参数太暴力了, 可能会丢数, 不推荐这么搞, 而SQL慢可能是IO压力太大的缘故, 下面通过一些工具来查看一下机器负载


## 查看硬盘负载


[**iostat**](http://linux.die.net/man/1/iostat) 命令可以查看磁盘负载, 输入命令

```
$ sudo iostat -d -x -k 1 40
```

![](http://box-images.qiniudn.com//blog/iostat-1.png)

其中 **%util** 字段表示一秒中有百分之多少的时间用于 I/O 操作，即被io消耗的cpu百分比, 如果 %util 接近 100%，说明产生的I/O请求太多，I/O系统已经满负荷，该磁盘可能存在瓶颈


## 查看进程IO占用

那么如何知道哪个程序占用的IO比较高呢? Linux下的 [**iotop**](http://guichaz.free.fr/iotop/)命令包你满意, 该命令可以用yum进行安装, 在机器上运行iotop的结果如下图所示

![](http://box-images.qiniudn.com//blog/iotop-1.png)

结果发现读IO进程主要是一个rsync脚本, 写IO进程是一堆爬虫以及elasticsearch...


## 解决方法

So..最后让另外的爬虫程序爬慢一点, insert 语句的速度变有了明显的提升 ([\#还是因为太穷没机器..ORZ\#](javascript:void))



