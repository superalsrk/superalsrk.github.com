---
title: 理解一致性Hash算法
date: 2017-10-12 16:15:53
tags: ['算法']
description: 一致哈希是一种特殊的哈希算法。在使用一致哈希算法后，哈希表槽位数（大小）的改变平均只需要对 K/n 个关键字重新映射，其中K是关键字的数量，n是槽位数量
keywords: ['一致性hash','consistent hashing']
---

## 摘要

一致哈希是一种特殊的哈希算法。在使用一致哈希算法后，哈希表槽位数（大小）的改变平均只需要对 K/n 个关键字重新映射，其中  K是关键字的数量，n是槽位数量, 因为这个特性, 一致性hash经常用于分布式存储系统中

## 算法描述

### 业务情景
假设有这么一个场景: 有10亿条数据, 需要放在N台机器上的缓存里, 应该怎么设计一个规则将这些数据均衡的放在这些机器中. 一个简单的方法是对每条记录 hash 然后取模 (即`hash(record）mod N`), 十分的简单, 假如我们要给这个已经运行的分布式的缓存系统加一台机器呢, 或者由于某些特殊的原因挂掉了一台器, 为了保证新的记录能够正确的映射, 那么取模的值就要变成 N+1 或者 N-1了, 进而导致现有的数据几乎全部要几星rebalnce操作, 耗费巨大

### 算法特性
一致性hash解决的就是上述问题: 在增减机器后, 尽可能少的减少需要reblance的记录个数, 一致性hash算法应该满足以下几个特点

+ 平衡性: 尽可能的将记录hash到所有节点当中, 最大化利用空间
+ 单调性: **哈希的结果应能够保证原有已分配的内容可以被映射到原有的或者新的缓冲中去，而不会被映射到旧的缓冲集合中的其他缓冲区**, 可以这么理解, 在增加一个节点之后, 原有的hash结果要么不迁移, 要么迁移到新的节点, 不会迁移到旧的节点中, 所以取模的那个方法, 增加节点之后很大一部分的key都会重新映射到原来的缓存系统的其他节点当中, 故不符合单调性, 在P2P系统中常用的DHT也用到了一致性Hash算法, 缓冲的变化等价于Peer加入或退出系统，这一情况在P2P系统中会频繁发生，因此会带来极大计算和传输负荷。单调性就是要求哈希算法能够应对这种情况。
+ 分散性: 分布式环境中用户可能看不到所有的节点, 所以可能导致相同记录映射到不同节点上, 这种情况显然不太好, 分散性就是定义上述情况发生的严重程度, 应该尽量降低分散性
+ 负载: 既然不同的终端可能将相同的内容映射到不同的分片节点中，那么对于一个特定的节点而言，也可能被不同的用户映射为不同的内容, 好的hash算法应该能够尽量降低节点负载
+ 平滑性: 缓存服务器数量能够和记录数量的改变能够保持一致

### 算法实现
一致性hash的算法实现如下

1. 根据(ip,port,mac等)求出节点的hash值, 分布在0-2^32的圆环上
![](/image/2017-10/consistent-hash-1.png)
2. 如果有一个写入缓存的请求，其中Key值为K，计算器hash值Hash(K)， Hash(K) 对应于图 – 1环中的某一个点，如果该点对应没有映射到具体的某一个机器节点，那么顺时针查找，直到第一次找到有映射机器的节点，该节点就是确定的目标节点，如果超过了2^32仍然找不到节点，则命中第一个机器节点。比如 Hash(K) 的值介于A~B之间，那么命中的机器节点应该是B节点
3. 如果增加一个节点, 会初始化该节点到现有的环上, 比如加入了节点F, 初始该节点后集群状态如下
![](/image/2017-10/consistent-hash-1.png)
那么只有C-F之间的区域的数据会出现节点不命中的情况, 将该区域的数据rebalance即可
4. 如果将F节点去掉, 那么还是只有C-F之间的区域数据会收到影响, 按照算法只要将F节点数据挪到D节点上即可

在实际的应用中, 如果节点数量过少, 会出现节点在环上比较近, 导致平衡性很低, 可以给具体实现的时候加入虚拟节点的思想: 为某个真实节点分配多个虚拟节点, 这样便能够一直分布不均匀的情况, [Ketama](https://github.com/RJ/ketama)库就采用的这种方法, 除此之外, 在上面那个讲F节点去掉的情况中, 原有的F节点上的数据都会落到D上, 可以实现数据落到C&D上, 减少了服务器压力


## 工程应用

### ShardedJedis

Jedis中使用ShardedJedis实现了集群特性(redis3的redis cluster也原生支持了), 实现一致性hash的主要思路是:

1. 虚拟节点采取TreeMap存储, 这样就能通过tailMap方法来实现环的特性
2. 真实节点采用LinkedHashMap存储, 这个当然也是环啊, 虽然实现中没有特意用到这个特性

```java
public class Sharded<R, S extends ShardInfo<R>> {

    public static final int DEFAULT_WEIGHT = 1;

    private TreeMap<Long, S> nodes;

    private final Hashing algo;

    private final Map<ShardInfo<R>, R> resources = new LinkedHashMap<ShardInfo<R>, R>();

    /*
     * 初始化过程, 可谓比较暴力了, 直接按节点顺序&Name来进行hash, 默认的hash算法是MurmurHash
     */
    private void initialize(List<S> shards) {
        nodes = new TreeMap<Long, S>();

        for (int i = 0; i != shards.size(); ++i) {
            final S shardInfo = shards.get(i);
            if (shardInfo.getName() == null) for (int n = 0; n < 160 * shardInfo.getWeight(); n++) {
                nodes.put(this.algo.hash("SHARD-" + i + "-NODE-" + n), shardInfo);
            }
            else for (int n = 0; n < 160 * shardInfo.getWeight(); n++) {
                nodes.put(this.algo.hash(shardInfo.getName() + "*" + shardInfo.getWeight() + n), shardInfo);
            }
            resources.put(shardInfo, shardInfo.createResource());
        }
    }

    /*
     * 先获取虚拟节点, 然后再获取真实节点
     */
    public R getShard(byte[] key) {
        return resources.get(getShardInfo(key));
    }
    
    /*
     * 获取虚拟节点
     */
    public S getShardInfo(byte[] key) {
        SortedMap<Long, S> tail = nodes.tailMap(algo.hash(key));
        if (tail.isEmpty()) {
        return nodes.get(nodes.firstKey());
        }
        return tail.get(tail.firstKey());
   }
}
```

## 参考

1. [一致性哈希算法原理](http://www.cnblogs.com/lpfuture/p/5796398.html)
2. [一致性哈希在分布式数据库中的应用探索](https://github.com/digoal/blog/blob/master/201607/20160723_03.md)
3. [一致性哈希算法的理解与实践](https://yikun.github.io/2016/06/09/%E4%B8%80%E8%87%B4%E6%80%A7%E5%93%88%E5%B8%8C%E7%AE%97%E6%B3%95%E7%9A%84%E7%90%86%E8%A7%A3%E4%B8%8E%E5%AE%9E%E8%B7%B5/)
4. [Jedis之ShardedJedis虚拟节点一致性哈希分析](http://m635674608.iteye.com/blog/2297632)
5. [LinkedHashMap is always better than HashMap](https://publicobject.com/2016/02/08/linkedhashmap-is-always-better-than-hashmap/)