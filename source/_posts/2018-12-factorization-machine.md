---
title: Factorization Machine
date: 2018-11-16 20:16:53
categories: ['机器学习']
tags: [ "算法"]
description: 因子分解机从入门到实践
keywords: ['统计学', 'FM', "机器学习", "因子分解机"]
toc: true
mathjax: true
---

## 引言

Factorization Machine 主要目标是: 在数据稀疏的情况下解决组合特征的问题


## 推导

一般的线性模型为(n为特征维度)

\begin{align}
\hat y = \omega\_0 + \sum_{i=1}^{n}\omega\_{i}x\_{i}
\end{align}

线性模型的各个特征是独立的, 但实际上有一些组合特征是很有意义的, 比如在新闻推荐系统中, 喜欢军事新闻的也很可能喜欢国际新闻,  喜欢时尚新闻的也很可能喜欢娱乐新闻, 把两两的特征组合考虑进去就能得到度为2的FM模型

\begin{align}
\hat y = \omega\_0 + \sum_{i=1}^{n}\omega\_{i}x\_{i} + \sum_{i=1}^{n}\sum_{j=i+1}^{n}\omega_{ij}x\_{i}x\_{j}
\end{align}


对于 \\( \omega_{ij} \\) 构成的实对称矩阵 \\( W \\), 该矩阵为正定矩阵, 可以进行矩阵分解

\begin{align}
W = VV^{T}
\end{align}

其中矩阵 \\( V \\) 为一个  \\( n \times k \\) 的矩阵, 关于k的选择论文中是这么说的

> It is well known that for any positive definite matrix W, there exists a matrix V such that W =V · Vt provided that k is sufficiently large. This shows that a FM can express any interaction matrix W if k is chosen large enough. Nevertheless in sparse settings, typically a small k should be chosen because there is not enough data to estimate complex interactions W. Restricting k – and thus the expressiveness of the FM – leads to better generalization and thus improved interaction matrices under sparsity


那么 FM公式中 \\( \omega_{ij} \\) 就可以表示为 矩阵\\( V \\) 中两个向量的点积

\begin{align}
\hat y & = \omega\_0 + \sum_{i=1}^{n}\omega\_{i}x\_{i} + \sum_{i=1}^{n}\sum_{j=i+1}^{n} <v_{i}, v_{j}>x_{i}x_{j}
\end{align}

这样二项式参数的数量就由原来的 \\( \frac{n(n-1)}{2}\\) 变成了  \\( nk \\), 而且对于原来的参数 \\( \omega_{hi}\\) 和 \\( \omega_{hj} \\) , 这两个参数是相互独立的, 在因子化之后就等同于 \\( <v_{h}, v_{i}>\\) 和  \\( <v_{h}, v_{j}>\\), 他们之间是有共同项的, 因此 所有包含 \\( x_{i} \\)的非0组合特征都可以用来学习隐向量 \\( v_{i}\\), 很大程度减少了数据稀疏带来的影响, 此外,上述公式的二次项部分算法复杂度为  \\( O(kn^2) \\)， 还可以进行优化

\begin{align}
\sum_{i=1}^{n}\sum_{j=i+1}^{n} <v_{i}, v_{j}>x_{i}x_{j} & = \frac{1}{2}\sum_{i=1}^{n}\sum_{j=1}^{n} <v_{i}, v_{j}>x_{i}x_{j} - \frac{1}{2}\sum_{i=1}^{n} <v_{i}, v_{i}>x_{i}x_{i} \\\\
& =\frac{1}{2} (\sum_{i=1}^{n}\sum_{j=1}^{n}\sum_{f=1}^{k}v_{i,f}v_{j,f}x_{i}x_{j} - \sum_{i=1}^{n}\sum_{f=1}^{k}v_{i, f}v_{i,f}x_{i}x_{i}) \\\\
& = \frac{1}{2}\sum_{f=1}^{k}((\sum_{i=1}^{n}v_{i,f}x_{i})(\sum_{j=1}^{n}v_{j,f}x_{j}) - \sum_{i=1}^{n} v_{i,f}^2 x_i^2)\\\\
& = \frac{1}{2}\sum_{f=1}^{k}((\sum_{i=1}^{n}v_{i,f}x_{i})^2 - \sum_{i=1}^{n} v_{i,f}^2 x_i^2)\\\\
\end{align}

此时的算法复杂度为 \\( O(kn) \\)

完整的FM模型公式为

\begin{align}
\hat y = \omega_0 + \sum_{i=1}^{n}\omega\_{i}x\_{i} + \frac{1}{2}\sum_{f=1}^{k}((\sum_{i=1}^{n}v_{i,f}x_{i})^2 - \sum_{i=1}^{n} v_{i,f}^2 x_i^2)
\end{align}


## 训练

因子分解机可以处理 Regression/Classification/Ranking问题

### 回归问题

回归问题中, 使用最小均方误差作为优化目标

\begin{align}
loss^{R}(\hat y, y) = \frac{1}{2m}\sum_{i=1}^{m}(\hat y^{(i)} - y^{(i)})^2
\end{align}


### 分类问题

CTR预测本质上就是一个二元分类问题, 结果为点击的概率。分类问题中 logloss 做损失函数, \\( \sigma \\) 为 sigmoid函数

\begin{align}
loss^{C}(\hat y, y) = \sum_{i=1}^{m} -ln\sigma(\hat y^{(i)}y^{(i)})
\end{align}



模型训练与预测的代码实现: https://github.com/Tara-X/algo/tree/master/fm


## 应用


作为一个2010年提出的模型, FM在工业界还依然有着很广泛的应用， 比如CTR预估, LearningToRank, 而且衍生出了DeepFM这种融合了深度学习的模型, FM模型的优点很明显

+ 适用于CTR预估这种稀疏矩阵的情况
+ 做好特征工程后就不用考虑组合特征了, 如果是在LR模型中添加组合特征, 则需要极其深刻的领域知识
+ 在线上进行预测时候速度快, 模型训练也快


下面简单的使用FM对 Kaggle criteo challenge 进行点击率预估


## 资料

+ [Factorization Machines论文](https://www.csie.ntu.edu.tw/~b97053/paper/Rendle2010FM.pdf)
+ [libfm实现](https://www.csie.ntu.edu.tw/~b97053/paper/Factorization%20Machines%20with%20libFM.pdf)
+ [从FM推演各深度CTR预估模型](https://zhuanlan.zhihu.com/p/39848122)
+ [FM（Factorization Machines）的理论与实践](https://zhuanlan.zhihu.com/p/50426292)
+ https://blog.csdn.net/g11d111/article/details/77430095
https://blog.csdn.net/hiwallace/article/details/81333604
+ https://blog.csdn.net/google19890102/article/details/45532745/


> 原创文章，转载请注明：转载自[叠搭宝箱](http://stackbox.cn)的博客
> 本文链接地址: https://stackbox.cn/2018-12-factorization-machine/