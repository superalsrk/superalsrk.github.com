---
title: 生产环境使用Airflow
date: 2017-05-12 18:36:37
tags:
description: Airflow是一个基于DAG(有向无环图)的任务管理系统
keywords:
---


airflow是airbnb家的基于DAG(有向无环图)的任务管理系统, 最简单的理解就是一个高级版的crontab, 他对标的是Azkaban，oozie，luigi,  为什么选airflow的原因在于, oozie实在是太古老了, luigi更新速度感人, Azkaban是java栈的, 对比下来airflow（1.8.1版本）是最能满足当下需求的了, 而且交互上的设计还是蛮优美的

<!-- more -->

### DAG设计

一个DAG是由一个或多个任务组成的, 这一块比较考验你对整个数据流程的设计, 具体可以参考[这篇文章](https://segmentfault.com/a/1190000005078547)

### Broker与Executor选择

请务必使用RabbitMQ+CeleryExecutor, 毕竟这个也是Celery官方推荐的做法, 这样就可以使用一些很棒的功能, 比如webui上点击错误的Task然后ReRun

### Supervisor

在使用supervisor的启动worker,server,scheduler的时候, 请务必给配置的supervisor任务加上


> environment=AIRFLOW_HOME=xxxxxxxxxx

主要原因在于如果你的supervisor是通过调用一个自定义的脚本来运行的,  在启动worker的时候会另外启动一个serve_log服务, 如果没有设置正确的环境变量, serve_log 会在默认的AIRFLOW_HOME里找日志, 导致无法在webui里查看日志

### Serve_log

如果在多个机器上部署了worker, 那么你需要iptables开启那些机器的8793端口, 这样webui才能查看跨机器worker的任务日志

### AMPQ库

celery提供了两种库来实现amqp, 一种是默认的kombu, 另外一个是librabbitmq, 后者是对其c模块的绑定,  在1.8.1版本中,  使用的kombu的时候会出现scheduler自动断掉的问题, 这个应该是其对应版本4.0.2的问题, 当切成librabbitmq的时候, server 与 scheduler运行正常, 但是worker的从来不consume任务, 最后查出原因: Celery4.0.2的协议发生了变化但是librabbitmq还没有对应修改, 解决方法是, 修改源码里的 executors/celery_executor.py文件然后加入参数

> CELERY_TASK_PROTOCOL = 1

### RabbitMQ连接卡死

运行一段时间过后, 由于网络问题导致所有任务都在queued状态, 除非把worker重启才能生效, 查资料有人说是clelery的broker pool有问题, 继续给celery_executor.py加入参数

> BROKER_POOL_LIMIT=0  //不使用连接池

另外这样只会减少卡死的几率, 最好使用crontab定时重启worker


### 特定任务只在特殊机器上运行

可以给DAG中的task指定一个queue, 然后在特定的机器上运行 airflow worker -q=QUEUE_NAME 即可实现

### RabbitMQ中的queue数量过多问题

celery为了让scheduler知道每个task的结果并且知道结果的时间为 O(1) , 那么唯一的解决方式就是给每一个任务创建一个UUID的queue, 默认这个queue的过期时间是1天, 可以通过更改celery_executor.py的参数来调节这个过期时间

> CELERY_TASK_RESULT_EXPIRES = **time in seconds**