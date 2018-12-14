---
title: 深入理解Supervisor事件机制
date: 2017-02-06 18:36:37
tags: ['工具']
description: 事件机制是在supervisor v3.0开始引入的一个高级特性, 常用情景是supervisor的报警系统
keywords:
---

## 事件协议

事件机制是在supervisor v3.0开始引入的一个高级特性, 常用于守护程序崩溃时候的报警(发邮件/发短信)

该事件机制是一个简单的 `Listener/Notification`模型, Listener通过标准输入来获取supervisor发来的事件通知, 然后通过标准输出来告诉supervisor事件处理结果。过程中传递的EventNotification 由head和body两部分组成

可以先通过stdout输出一个 `READY\n` 字符串来表明开始接受事件, 然后通过 `sys.stdin.readline()` 来获取head信息, head的结构如下:

```
ver:3.0 server:supervisor serial:35 pool:event_listener poolserial:35 eventname:PROCESS_STATE_RUNNING len:91
```

+ ver: 版本信息
+ serial: supervisor给事件的编号, 第一个事件为1, 之后事件编号递增
+ eventpool: 产生event的event_listener名字
+ poolserial: 与serial不同的是, 由于可以有多个eventpool,而且eventpool可以检测的范围事件范围可以不同， 这个poolserial是相对某个eventpool的编号
+ eventname: supervisor 标准定义的事件状态
+ len: **data长度, 此长度十分重要,需要再通过标准输入读入len长度的数据, 某个event_notification才算读取完毕**

然后按照head的信息, 读入长度为len的数据, 这个数据就是event的data部分:

```
processname:application_demo_03 groupname:application_demo_03 from_state:STARTING pid:81292
```

+ processname: 触发事件的applicaiton名称
+ groupname: 触发事件的application的组名称
+ from_state: 事件触发状态之前的那个状态
+ pid: 进程id

处理完事件之后, 可以通过标准输出 `RESULT 2\nOK` 来告诉supervisor已经处理完事件

## 使用

```python
import sys
import os

def write_stdout(s):
    sys.stdout.write(s)
    sys.stdout.flush()
    
def main():
    while 1:
        # transition from ACKNOWLEDGED to READY
        write_stdout('READY\n')

        # read header line and print it to stderr
        line = sys.stdin.readline()

        with open('event.log', 'a') as f:
            f.write(line)

        headers = dict([ x.split(':') for x in line.split() ])
        data = sys.stdin.read(int(headers['len']))

        with open('event.log', 'a') as f:
            f.write(data)
            f.write('\n\n')

        write_stdout('RESULT 2\nOK')
        
if __name__ == '__main__':
    main()
```

上边这种是比较原始事件处理方法, supervisor自带的childutils可以帮助你方便的处理事件

```python
import os
import sys
import json

from supervisor import childutils

def main():
    while 1:
        headers, payload = childutils.listener.wait(sys.stdin, sys.stdout)
        
        with open('event.pro.log', 'a') as f:
            f.write(json.dumps(headers))
        childutils.listener.ok(sys.stdout)
if __name__ == '__main__':
    main()
```


## 注意事项

1. 在配置文件中配置event_listener的时候, 需要配置一个 events 的选项, 用以表明只监听某些类型的事件, 可以设置多个事件类型
2. 监听器的处理事件流程为: `readline()读取head -> 读取固定长度的data -> 输出状态信息` **所以尽量避免在其中使用 `print` 等标准输出,**,否则会破坏协议的完整性导致监听器失效, 如果想查看输出日志可以用文件或者网络传输等方式
3. [测试代码](https://github.com/Tara-X/supervisor-event-listener-demo)



