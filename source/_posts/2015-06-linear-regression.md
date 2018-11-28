---

title: 线性回归
date: 2015-06-05 13:41:41
mathjax: true
toc: true
tags: ["机器学习"]
categories: ['机器学习']
keywords: ['线性回归', '机器学习']
description: 机器学习之线性回归

---

## 基本概念 ##
+ 训练集 ''(Training set)''

$$ (x^{(0)},y^{(0)}),(x^{(1)},y^{(1)}),(x^{(2)},y^{(2)}).....(x^{(i)},y^{(i)}) $$

+ 假设函数''(Hypothesis fuction)''

$$ h_\theta(x)=\theta_0 + \theta_1x $$

+ 代价函数''(Cost fuction)''

:线性回归的目标是让 假设函数与训练集尽量的拟合，使得代价函数最小,前面的 \\( 1/2 \\)的作用是因为平方误差函数求导之后正好抵消,使得在梯度下降里面的偏导数项系数正好为1


$$ J(\theta\_0, \theta\_1) = \frac{1}{2m} \sum\_{i=1}^{m}(h\_\theta(x^{(i)}) - y^{(i)})^2 $$

## 梯度下降算法 ##

以 $$ \theta_0 , \theta_1, J(\theta_0,\theta_1) $$画坐标系, 会得到类似下面的图像, 实际上对于线性的假设函数来说，整个图像会是一个弓形图，
从任何地方会收敛到同一个最优点。梯度是一个方向导数, 在该方向上函数变化最大。


<img src="http://mirror.tarax.cn/liner-01.webp" style="width:500px">

递归下降的公式为,其中 j 为 0 和 1,  \\( \alpha \\)叫做learning rate, 在几何上表现为每次下降的步长

$$ \theta_j := \theta_j - \alpha\frac{\partial}{\partial\theta_j}J(\theta_0,\theta_1) $$

## 线性回归&梯度下降公式推导 ##

推导过程的重点就是算代价函数 \\( J(\theta_0,\theta_1) \\)关于 \\( \theta_0 \\)和 \\( \theta_1 \\)的偏导数

### \\( \theta_0 \\)的推导 ###

\begin{align}
\theta\_0 & := \theta\_0 - \alpha\frac{\partial}{\partial\theta\_0}J(\theta\_0,\theta\_1) \\\\
& = \theta\_0 - \alpha\frac{\partial}{\partial\theta\_0} \frac{1}{2m} \sum\_{i=1}^{m}(h\_\theta(x^{(i)}) - y^{(i)})^2 \\\\
& = \theta\_0 - \alpha\frac{\partial}{\partial\theta\_0} \frac{1}{2m} \sum\_{i=1}^{m}(\theta\_0 + \theta\_1x^{(i)} - y^{(i)})^2 \\\\
& = \theta\_0 - \alpha\frac{\partial}{\partial\theta\_0} \frac{1}{2m} \sum\_{i=1}^{m}(\theta\_0^2 + 2\theta\_0(\theta\_1x^{(i)} - y^{(i)}) + (\theta\_1x^{(i)} - y^{(i)})^2) \\\\
&= \theta\_0 - \alpha\frac{1}{2m} \sum\_{i=1}^{m}(2\theta\_0 + 2(\theta\_1x^{i} - y^{i})) \\\\
& = \theta\_0 - \frac{\alpha}{m}  * \sum\_{i=1}^{m}(h\_\theta(x^{(i)}) - y^{(i)})
\end{align}

### \\( \theta_1 \\)的推导 ###
\begin{align}
\theta\_0 & := \theta\_1 - \alpha\frac{\partial}{\partial\theta\_1}J(\theta\_0,\theta\_1) \\\\
& = \theta\_1 - \alpha\frac{\partial}{\partial\theta\_1} \frac{1}{2m} \sum\_{i=1}^{m}(h\_\theta(x^{(i)}) - y^{(i)})^2 \\\\
& = \theta\_1 - \alpha\frac{\partial}{\partial\theta\_1} \frac{1}{2m} \sum\_{i=1}^{m}(\theta\_0 + \theta\_1x^{(i)} - y^{(i)})^2 \\\\
& = \theta\_1 - \alpha\frac{\partial}{\partial\theta\_1} \frac{1}{2m} \sum\_{i=1}^{m}((\theta\_1 x^{i})^2 + 2\theta\_1x^{(i)}(\theta_0 - y^{(i)}) + (\theta_0 - y^{(i)})^2) \\\\
& = \theta\_1 - (\alpha \frac{1}{2m}  \sum\_{i=1}^{m}(2\theta_1 (x^{(i)})^2 + 2x^{(i)}(\theta_0 - y^{(i))})  \\\\
& = \theta\_1 - \frac{\alpha}{m}  * \sum\_{i=1}^{m}(h\_\theta(x^{(i)}) - y^{(i)})x^{(i)}
\end{align}
### 结论 ###

收敛算法为：

<img src="http://mirror.tarax.cn/liner-02.webp" style="width:500px">

## 试验 ##

 [线性回归课后练习](http://openclassroom.stanford.edu/MainFolder/DocumentPage.php?course=MachineLearning&doc=exercises/ex2/ex2.html)
 [下载训练集](http://openclassroom.stanford.edu/MainFolder/courses/MachineLearning/exercises/ex2materials/ex2Data.zip)





## 参考资料

+ [梯度下降之导数与梯度理解](https://blog.csdn.net/qq_37553011/article/details/79795092)
+ [如何直观形象的理解方向导数与梯度以及它们之间的关系？](https://www.zhihu.com/question/36301367)
+ [梯度下降推导](https://blog.csdn.net/u012421852/article/details/79558833)
+ [方向导数偏导数梯度](https://blog.csdn.net/fffupeng/article/details/73522425)
+ [随机梯度下降](https://blog.csdn.net/kwame211/article/details/80364079)