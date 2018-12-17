---

title: 线性回归
date: 2018-10-05 13:41:41
mathjax: true
toc: true
tags: ["机器学习"]
categories: ['机器学习']
keywords: ['线性回归', '机器学习']
description: 机器学习之线性回归

---

## 引言

这篇文章本来是2015年看Ng的视频做的笔记, 目前看有一些东西当时理解的太浅, 故修补之后重新发一下

<!-- more -->

## 基本概念 ##

+ 代价函数/损失函数 **(Cost fuction)**

:线性回归的目标是让 假设函数与训练集尽量的拟合，使得代价函数最小,前面的 \\( 1/2 \\)的作用是因为平方误差函数求导之后正好抵消,使得在梯度下降里面的偏导数项系数正好为1


$$ J(\theta\_0, \theta\_1) = \frac{1}{2m} \sum\_{i=1}^{m}(h\_\theta(x^{(i)}) - y^{(i)})^2 $$

## 梯度下降算法 ##

### 梯度下降公式

以 \\( \theta_0 , \theta_1, J(\theta_0,\theta_1) \\) 画坐标系, 会得到类似下面的图像, 实际上对于线性的假设函数来说，整个图像会是一个弓形图，
从任何地方会收敛到同一个最优点。梯度是一个方向导数, 在该方向上函数变化最大。



| 梯形图 | 梯度下降公式|
|--------|-------------|
|<img src="http://mirror.tarax.cn/liner-01.webp" style="width:300px"> |$$ \theta_j := \theta_j - \alpha\frac{\partial}{\partial\theta_j}J(\theta_0,\theta_1) $$ |


### 理解梯度

+ 梯度即变化率最大的那个方向导数
+ 偏导数是一类特殊的方向导数
+ 求得某点的各方向偏导数, 可以构成一个向量, 沿着该向量变化最大, 即方向导数







## 多元线性回归

上面的那个公式推导其实有一些蠢, 我们来考虑多元的情况, k为dimension

\begin{align}
\hat{y} = \omega_{0} + \sum_{i=1}^{k}\omega_{i}x_{i}
\end{align}

然后其损失函数为

\begin{align}
loss^{R} =  \frac{1}{2m}\sum_{i=1}^{m}(\hat{y}^{(i)} - y^{(i)})^2
\end{align}

该损失函数的偏导数为 (** 可以直接求偏导, 比如 \\( \hat{y} \\) 对 \\( \omega_2 \\) 求偏导就是 \\( x_2 \\) ** )


\begin{align}
\frac{\partial{loss^{R}}}{\partial\theta} = \begin{cases}
\frac{1}{m}\sum_{i=1}^{m}(\hat{y}^{(i)} - y^{(i)})   & \text{if  } \theta \text{ equals to } \omega_{0} \\\\
\\\\
\\\\
\frac{1}{m}x_{t}\sum_{i=1}^{m}(\hat{y}^{(i)} - y^{(i)})  & \text{if  } \theta \text{ equals to } \omega_{t}
\end{cases}
\end{align}

然后就可以梯度下降求解, 常见的梯度下降方法有

+ Batch Gradient Descent (BGD) 批量梯度下降, 每次迭代使用全部训练数据
+ Stochastic Gradient Descent (SGD) 随机梯度下降, 每次仅仅选取一个样本来求梯度
+ Mini-Batch Gradient Descent (MBGD) 小批量梯度下降，每次抽取x个样本进行训练


## 模型评估

对于线性回归模型, 可以用以下方法来进行模型效果评估



## 代码实现

https://github.com/Tara-X/algo/tree/master/linear


## 参考资料

+ [梯度下降之导数与梯度理解](https://blog.csdn.net/qq_37553011/article/details/79795092)
+ [如何直观形象的理解方向导数与梯度以及它们之间的关系？](https://www.zhihu.com/question/36301367)
+ [梯度下降推导](https://blog.csdn.net/u012421852/article/details/79558833)
+ [方向导数偏导数梯度](https://blog.csdn.net/fffupeng/article/details/73522425)
+ [随机梯度下降](https://blog.csdn.net/kwame211/article/details/80364079)


> 原创文章，转载请注明：转载自[叠搭宝箱](http://stackbox.cn)的博客
> 本文链接地址: https://stackbox.cn/2018-10-linear-regression