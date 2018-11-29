---
title: Factorization Machine
date: 2018-11-16 20:16:53
categories: ['机器学习']
tags: [ "算法"]
description: 因子分解机
keywords: ['统计学', 'FM', "机器学习", "因子分解机"]
toc: true
mathjax: true
---

## 引言

Factorization Machine 主要目标是: 在数据稀疏的情况下解决组合特征的问题


## 推导

一般的线性模型为(n为特征维度)

\begin{align}
y = \omega\_0 + \sum_{i=1}^{n}\omega\_{i}x\_{i}
\end{align}

线性模型的各个特征是独立的, 但实际上有一些组合特征是很有意义的, 比如在新闻推荐系统中, 喜欢军事新闻的也很可能喜欢国际新闻,  喜欢时尚新闻的也很可能喜欢娱乐新闻, 把两两的特征组合考虑进去就能得到度为2的FM模型

\begin{align}
y = \omega\_0 + \sum_{i=1}^{n}\omega\_{i}x\_{i} + \sum_{i=1}^{n}\sum_{j=i+1}^{n}\omega_{ij}x\_{i}x\_{j}
\end{align}


对于 \\( \omega_{ij} \\) 构成的实对称矩阵 \\( W \\), 该矩阵为正定矩阵, 可以进行矩阵分解

\begin{align}
W = VV^{T}
\end{align}

其中矩阵 \\( V \\) 为一个  \\( n \times k \\) 的矩阵, 关于k的选择论文中是这么说的

> It is well known that for any positive definite matrix W, there exists a matrix V such that W =V · Vt provided that k is sufficiently large. This shows that a FM can express any interaction matrix W if k is chosen large enough. Nevertheless in sparse settings, typically a small k should be chosen because there is not enough data to estimate complex interactions W. Restricting k – and thus the expressiveness of the FM – leads to better generalization and thus improved interaction matrices under sparsity


那么 FM公式中 \\( \omega_{ij} \\) 就可以表示为 矩阵\\( V \\) 中两个向量的点积

\begin{align}
y & = \omega\_0 + \sum_{i=1}^{n}\omega\_{i}x\_{i} + \sum_{i=1}^{n}\sum_{j=i+1}^{n} <v_{i}, v_{j}>x_{i}x_{j}
\end{align}


这个公式的算法复杂度为  \\( O(n^2) \\)， 还可以进行优化

\begin{align}
\sum_{i=1}^{n}\sum_{j=i+1}^{n} <v_{i}, v_{j}>x_{i}x_{j} & = \frac{1}{2}\sum_{i=1}^{n}\sum_{j=1}^{n} <v_{i}, v_{j}>x_{i}x_{j} - \frac{1}{2}\sum_{i=1}^{n} <v_{i}, v_{i}>x_{i}x_{i} \\\\
& =\frac{1}{2} (\sum_{i=1}^{n}\sum_{j=1}^{n}\sum_{f=1}^{k}v_{i,f}v_{j,f}x_{i}x_{j} - \sum_{i=1}^{n}\sum_{f=1}^{k}v_{i, f}v_{i,f}x_{i}x_{i}) \\\\
& = \frac{1}{2}\sum_{f=1}^{k}((\sum_{i=1}^{n}v_{i,f}x_{i})(\sum_{j=1}^{n}v_{j,f}x_{j}) - \sum_{i=1}^{n} v_{i,f}^2 x_i^2)\\\\
& = \frac{1}{2}\sum_{f=1}^{k}((\sum_{i=1}^{n}v_{i,f}x_{i})^2 - \sum_{i=1}^{n} v_{i,f}^2 x_i^2)\\\\
\end{align}

此时的算法复杂度为 \\( O(nk) \\)

完整的FM模型公式为

\begin{align}
y = \omega_0 + \sum_{i=1}^{n}\omega\_{i}x\_{i} + \frac{1}{2}\sum_{f=1}^{k}((\sum_{i=1}^{n}v_{i,f}x_{i})^2 - \sum_{i=1}^{n} v_{i,f}^2 x_i^2)
\end{align}


## 应用



## 资料

+ [Factorization Machines论文](https://www.csie.ntu.edu.tw/~b97053/paper/Rendle2010FM.pdf)
+ [从FM推演各深度CTR预估模型](https://zhuanlan.zhihu.com/p/39848122)
+ [FM（Factorization Machines）的理论与实践](https://zhuanlan.zhihu.com/p/50426292)
+ https://blog.csdn.net/g11d111/article/details/77430095