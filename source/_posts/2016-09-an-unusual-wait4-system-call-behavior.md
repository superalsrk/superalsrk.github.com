---
title: 一个奇怪的wait4行为
date: 2016-09-07 14:16:32
tags: ['计算机基础']
description: OSX/Linux 下 signal handler 和 wait4同时使用引起的奇怪问题
keywords: ['Linux','Python']
toc: true
---


# 前言

最近写Python的时候发现了一个Mac奇怪的问题, 代码逻辑大致为

+ 给`SIGCHLD`信号绑定一个singal handler
+ fork多个子进程, 子进程阻塞
+ 主进程使用wait来阻塞, 并打印关闭的子进程信息

<!-- more -->

```python
import os
import time
import signal

def handler(a, b):
    print ('xxxxxxx:', a, b)
    signal.signal(signal.SIGCHLD, handler)
signal.signal(signal.SIGCHLD, handler)

for i in range(0, 5):
    pid = os.fork()
    if pid == 0:
        while True:
            time.sleep(2)

while True:
    pid , sta = os.wait()
    print ('pid:', pid, 'stat:', sta)

```

而奇怪的行为就是

+ Mac下wait如果没有被try except, 会扔一个EINTR错误 (慢系统调用中断错误)
+ Linux下及时没有try except却没有什么问题

# 分析

一开始怀疑的是 Python在OSX下的特殊bug, 然后我就用pyenv从2.7.1到3.5.0全部安了一遍, 最后发现3.5.0之后竟然没有EINTR错误, 查了一下3.5.0的 [release note](https://docs.python.org/3.5/whatsnew/changelog.html#python-3-5-0-final), 此版本解决了[#Issure19580](http://bugs.python.org/issue19850), 就是在添加signal handler的时候添加了了一句 `signal.siginterrupt(sig, False)`, 这样产生的效果就是某个Signal中断系统调用时, 不再抛出EINTER异常, 而是系统调用会自动重启。


但是这样还是无法解释老版本python在不同平台行为不一致的问题，那么会不会是另外一种情况? 信号并不会对 wait system call产中中断, 虽说各种手册都说wait跟read一样都属于slow system call, 感觉上应该不是这个问题, 不过为了严谨起见还是测试了一下, 大概是给上面的demo绑定一个 `SIGWINCH` 信号的signal handler, 这个信号会在终端宽度变化时会触发, 果不其然, 无论你主进程是用 `os.read` 还是 `os.wait` 来阻塞, 无论是在 OSX还是Linux下, 触发SIGWINCH都会抛出EINTR错误。


这就很尴尬了, 难道说是Linux下对SIGCHLD信号有特殊的关爱? 由于没见任何手册说过, 表示对这个猜想持保留意见, 幸运的是, 查资料的时候发现了 `strace/dtruss` 这类工具, 可以方便的跟踪系统调用信号 


```txt
# OSX下dtruss系统调用信息
83483/0xb96f97:     43901 13551362     10 wait4(0xFFFFFFFF, 0x7FFF5D80553C, 0x0)                 = -1 Err#4
83483/0xb96f97:     43915      80      2 sigreturn(0x7FFF5D805470, 0x1E, 0x0)            = 0 Err#-2
83483/0xb96f97:     43951      10      6 write_nocancel(0x1, "('xxxxxxx:', 20, <frame object at 0x102970c90>)\n\0", 0x30)                = 48 0
83483/0xb96f97:     43960       4      0 sigaction(0x14, 0x7FFF5D805128, 0x7FFF5D805150)                 = 0 0
83483/0xb96f97:     43977       5      2 write_nocancel(0x1, "exception\n\0", 0xA)               = 10 0
83483/0xb96f97:     43987       8      5 wait4(0xFFFFFFFF, 0x7FFF5D80553C, 0x0)          = 83520 0
83483/0xb96f97:     43995       4      1 write_nocancel(0x1, "('pid:', 83520, 'stat:', 9)\n\0", 0x1C)            = 28 0
```

这个是OSX下kill一个子进程之后的跟踪报告, 为了方便我在os.wait 外包了一层try cache, 可以看到, 第一行上来wait就扔了一个Err#4, 查了一下FreeBSD的文档发现 这个 Err#4 代表的是 Interrupted 的意思, 这个跟想象中的一样, SIGCHLD信号中断了 wait, sigreturn是和signal hanlder成对出现的(sigreturn的设计很有意思, 这个以后再细说), 在追踪报告中第三行就是handler的代码, 由于主进程EINTR了, 系统又重新绑定了一次signal handler(因为系统其实已经挂掉了..只不过try except +1s了, 所以需要重新绑信号), 然后此时又开始wait阻塞了,而且正好有一个僵尸进程, wait就开开心心的跑起来了

Note: 如果显式的调用 `signal.signal(signal.SIGCHLD, signal.SIG_IGN)` , 子进程被kill时会直接没掉, 不会产生僵尸进程, 此时主进程wait就不能感知子进程挂掉了, 如果绑定的是一个自定义的handler, 子进程还是会转成僵尸进程, 就会被主进程wait感知


```txt
# Linux下strace系统调用信息
[pid 25814] wait4(-1,
[pid 25814] <... wait4 resumed> [{WIFSIGNALED(s) && WTERMSIG(s) == SIGQUIT && WCOREDUMP(s)}], 0, NULL) = 25904
[pid 25814] --- SIGCHLD (Child exited) @ 0 (0) ---
[pid 25814] rt_sigreturn(0xffffffff)    = 25904
[pid 25814] write(1, "(17, <frame object at 0x7ffc4a17"..., 39(17, <frame object at 0x7ffc4a171910>)) = 39
[pid 25814] write(1, "--> 25904 131\n", 14--> 25904 131) = 14
```

然后这个是代码在Linux下的追踪报告, 第一行是表示的是wait目前在阻塞状态, kill一个子进程时, 第二行竟然是 ** wait4 resumed ** , 查看文档可以明白 ** <xxxx resumed> ** 代表system call 返回的意思, 注意注意: 此时还特么没有产生SIGCHLD信号, 也就是说:

> 在子进程转换成僵尸进程的时候就立刻被主进程wait感知了, 而且此时主进程还没有第一时间接收到SIGCHLD信号,自然SIGCHLD信号就不会中断系统调用了。** 

后面就是正常的跑 signal handler和主进程的代码了, 得知这种真相的我, 内心有点崩溃


# 总结


## 处理僵尸进程

一般而言处理僵尸进程的方式有两种

+ `signal.signal(signal.SIGCHLD, signal.SIG_IGN)`
+ 主进程wait处理关闭的子进程, 此时需要注意此文说明的问题


## 正确使用wait

为了不抛出EINTR异常, 可以有以下方式

+ 绑定signal handler的时候, 手动设置 `signal.siginterrupt(sig, False)`, 虽然3.5.0会自动设置, 但是为了老版本最好手动加一下
+ 主进程 `os.wait` 的时候try except
+ 主进程 不用 `os.wait` 阻塞, 而是不停地 `os.waitpid(-1, os.WNOHANG)` 来获取子进程信息, 返回结果为0时直接continue
+ 也可以在 signal handler里进行 `os.wait` , 这样就保证了信号和终端的顺序, 就不会产生EINTR错误, 一些官方的linux c教程也是这么写的



