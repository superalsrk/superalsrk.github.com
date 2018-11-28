---
title: 布隆过滤器 
date: 2018-11-16 19:15:53
categories: ['计算机基础']
tags: [ "算法"]
description: 布隆过滤器
keywords: ['LSH', 'minhash', 'simhash']
---




## 应用场景

bigtable/hbase 都有使用布隆过滤器来查找行列信息, 减少磁盘查找的IO次数

guava 中自带一个bloom filter的实现