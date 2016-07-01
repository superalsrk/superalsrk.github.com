---
title: 不定期更新的SpringBoot注意事项
date: 2016-05-20 14:33:36
tags:
description:
keywords:
---

### 2016.05.20-Mybatis失效问题

1. 在将版本从1.3.3升级到1.3.5的时候报错: `cannot get connection, url is null`
2. 报错出现在mybatis的mapper里, 但是另外那种JPA的方式没问题
3. 所以一种原因是, SqlSessionFactory有问题, 虽然注入了但是mybatis没有用这个sqlsessionfactory, 而是使用了默认的的sqlsessionfactory, 所以没URL
4. 另外整合mybatis的时候引用了 spring-context-support和mybaits-spring这两个包, 大概是spring升级引起了一些接口变化导致以前的包失效
5. 升级了一下上面的哪两个包, 1.3.5正常了

