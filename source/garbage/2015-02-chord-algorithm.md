---

title: Chord算法
date: 2015-02-10 00:53:31
tags: ['算法','分布式']
description: "一种P2P查找算法"
keywords: "Chord,分布式查找算法"
mathjax: true
---

在分布式计算中,如何快速查找存储有某段数据的节点是最核心的问题之一,Chord算法就是解决此类问题的方法之一

<!--more-->
##基本概念

###覆盖网络(overlaynetwork)###

覆盖网络是这么一种网络:构建在其他网络之上、网络节点之间通过虚拟或逻辑连接在一起，比如云计算、分布式系统都是覆盖网络，因为其都构建于TCP/IP之上，且节点之间有联系。

###结构化网络###

传统的非结构化网络,节点与节点之间不存在组织关系,其查找算法一般有如下几种:

1. Napster: 使用一个中心服务器处理所有的查询请求,中心服务器挂掉整个服务就挂掉了
![](/image/chord/napster.png)
2. Gnutella: 使用消息洪泛定位数据,查询消息发送到每个节点,一般会使用TTL来限制消息的转发次数,但是当网络规模
较大时网络负载会变大.
![](/image/chord/gnutella.png)
3. SN型: 即超级节点,和Napster时分类似,不过在整个网络中有多个中心节点,索引消息会在这些SN中进行传播,不过依然可能系统崩溃

###DHT


##算法概述

###Chord环构造

1. 假设存在一个最大容量为 $x\_mu$  的环形网络,我们假设以K代表资源,N代表节点,ID表示抽象环形网络中的标识符
![](/image/chord/chord1.png)
2. **ID(Node) = hash(IP,Port)**, 将Node散列在Chord环中,一般选用 hash-1算法
![](/image/chord/chord2.png) 
3. 之后开始对资源节点进行散列 **ID(Key) = hash(Key)**,对于K1来说, ID(1)不仅是个标识符,而且有节点存在,所以K1就放在了ID(1)上
![](/image/chord/chord4.png)
4. 对于K2来说,K2只是一个标识符,不存在节点,ID(2)的继承节点是ID(3),所以K2放在了ID(3)上
![](/image/chord/chord6.png)
5. 同理,K6本应该在节点ID(6)上,但是ID(6)不存在节点且其继承节点是ID(0),所以K6放在了ID(0)上
![](/image/chord/chord7.png)

###Finger路由表
###节点查找
1. 近似二分查找
2. 直到找到资源为止

###节点加入
1. 加入某节点N(n)后,构造Finger路由表
2. 如果存在K(n),则将K(n)从其他节点转移到N(n)
3. 其他节点的Finger路由表中,如某节点的Successor为N(n)的Successor,则重新指向为N(n)

###节点退出
1. 某节点N(n)退出时, 先将它所有的资源都转移到该节点的Successor中
2. 删除节点
3. 其他节点的Finger路由表中,若某节点的Successor为N(n),则重新指向为N(n)的Successor

###节点失效

##参考资料
1. [结构化P2P网络chord算法研究与分析](http://www.yeolar.com/note/2010/04/06/p2p-chord/)
2. [Chord slide of berkeley](http://www.cs.berkeley.edu/~kubitron/courses/cs294-4-F03/slides/lec03-chord.ppt)
3. [Chord sigcomm](http://pdos.csail.mit.edu/papers/chord:sigcomm01/chord_sigcomm.pdf)
4. [Chord算法（原理）](http://blog.csdn.net/chen77716/article/details/6059575)
5. [Chord算法详解](http://blog.csdn.net/wangxiaoqin00007/article/details/7374833)