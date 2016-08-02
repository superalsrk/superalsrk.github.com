---
title: 由升级GCC引发的惨案
date: 2015-10-13 19:26:20
tags: ['各种坑']
categories: ['运维','Linux']
description: 解决老旧的CentOS升级GCC引发的Assembler Error问题
keywords: ['GCC错误', 'gcc升级']
---


事件的起因是这样的, 今天在一台老旧的CentOS5服务器上装 `node-zerorpc` 的时候提示:

>  我们要用C++11辣, 快滚回去升级G++

好吧, 既然都这么说了....然后就参考了[这个链接](http://engine.wohlnet.ru/forum/viewtopic.php?f=17&t=330) 和一些SF的回答整出来下面这个脚本

```bash
cd /etc/yum.repos.d
wget http://people.centos.org/tru/devtools-2/devtools-2.repo 
yum install devtools-2
yum install devtoolset-2-gcc devtoolset-2-gcc-c++

## 之后讲/usr/bin的gcc备份了再将 /opt/rh/devtools-2 中的gcc/g++ 软连接过去
## 此处略
```

我还心想着, 老纸都升到了4.8了, 还怕你C++11不成, 大概被小僧的魅力折服(骗鬼呢！), 安装过程中果然没报版本过低的错误,报的是 **Assembler Error**, 这个问题Google上无解, 唯一提及的是几个GCC的Bug Issure, 但显然无法解决问题, 当时猜测的是需要重新编译Node, 编译的过程的错误日志如下:

```
/tmp/cc8TKj9o.s: Assembler messages:
/tmp/cc8TKj9o.s:125: Error: unknown .loc sub-directive `discriminator'
/tmp/cc8TKj9o.s:125: Error: junk at end of line, first unrecognized character is `1'
/tmp/cc8TKj9o.s:140: Error: unknown .loc sub-directive `discriminator'
/tmp/cc8TKj9o.s:140: Error: junk at end of line, first unrecognized character is `2'
/tmp/cc8TKj9o.s:143: Error: unknown .loc sub-directive `discriminator'
/tmp/cc8TKj9o.s:143: Error: junk at end of line, first unrecognized character is `2'
/tmp/cc8TKj9o.s:146: Error: unknown .loc sub-directive `discriminator'
/tmp/cc8TKj9o.s:146: Error: junk at end of line, first unrecognized character is `2'
/tmp/cc8TKj9o.s:150: Error: unknown .loc sub-directive `discriminator'
/tmp/cc8TKj9o.s:150: Error: junk at end of line, first unrecognized character is `2'
/tmp/cc8TKj9o.s:171: Error: unknown .loc sub-directive `discriminator'
/tmp/cc8TKj9o.s:171: Error: junk at end of line, first unrecognized character is `1'
/tmp/cc8TKj9o.s:179: Error: unknown .loc sub-directive `discriminator'
/tmp/cc8TKj9o.s:179: Error: junk at end of line, first unrecognized character is `1'
/tmp/cc8TKj9o.s:187: Error: unknown .loc sub-directive `discriminator'
```

之后又写了一个 **HelloWorld** 用新编译器编译下, 结果是同样类型的错误, 那么问题原因确定了: **编译器出问题了!**

哪里出问题了呢？ 正在头大的时候突然想到一个Issure, 内容大致为

> gcc和g++的版本不一致的时候可能会出现Assember Error

那么既然这样的话, 把整套GNU套件都装上会怎么样呢? 果然, 问题解决了。

附录: 正确的升级脚本

```bash 
cd /etc/yum.repos.d
wget http://people.centos.org/tru/devtools-2/devtools-2.repo 
yum install devtoolset-2

#临时改变gcc版本
scl enable devtoolset-2 bash
```


## Update (2016.08.02)

今天在一台纯CentOS6.4的Server上更新g++ 报错, 大致原因是有一堆GUI的依赖没有安装, 但是我只想更新编译器不想更新其他的,

查了一下文档发现devtools包含的模块主要有一下几个

| Package Name | Description | Installed Components |
|--------------|-------------|----------------------|
|devtoolset-2-ide | Integrated Development Environment | Eclipse |
|devtoolset-2-perftools | Performance monitoring tools | SystemTap, Valgrind, OProfile, Dyninst|
|devtoolset-2-toolchain | Development and debugging tools | GCC,GDB,binutils, elfutils, dwz, memstomp, strace|
|devtoolset-2-vc | Reveision control systems | Git|

所以。。只需要安装 **devtoolset-2-toolchain** 即可

```
$ cd /etc/yum.repos.d
$ wget http://people.centos.org/tru/devtools-2/devtools-2.repo 
$ sudo yum install devtoolset-2-toolchain
$ scl enable devtoolset-2 bash
``` 


