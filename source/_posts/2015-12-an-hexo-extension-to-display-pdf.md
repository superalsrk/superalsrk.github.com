---
title: 写了一个Hexo插件
date: 2015-12-04 14:50:41
tags: ['前端']
categories: ['工具', 'Hexo']
description: 用来在Hexo中插入PDF
keywords:
---

项目地址为: https://github.com/superalsrk/hexo-pdf , 已经PR到[官网](https://hexo.io/plugins/), 欢迎吐槽, 做这个插件的原因是

> 1. Slideshare在赵国被墙, WTF
> 2. 国内的豆丁,CSDN,微盘分享都是基于Flash的, Safari不支持

而官方的demo要么太简单要么太复杂, 作为一个css手残党连抄代码都不会抄, 进而一个猥琐的想法便诞生了

> 1. github page部署一个官方的Viewer, pdf文件地址从url参数中读取
> 2. hexo 页面中嵌入一个iframe, src为 Viewer地址+pdf地址

昂, 具体安装方法见 [README.md](https://github.com/superalsrk/hexo-pdf/blob/master/README.md), 最终效果如下

### Normal PDF
{% pdf http://7xov2f.com1.z0.glb.clouddn.com/bash_freshman.pdf %}

### Google drive
{% pdf https://drive.google.com/file/d/0B6qSwdwPxPRdTEliX0dhQ2JfUEU/preview %}

### Slideshare
{% pdf http://www.slideshare.net/slideshow/embed_code/key/8Jl0hUt2OKUOOE %}


## History

+ 2015-01-02: 支持嵌入googledoc和slideshare的文档
+ 2015-12-04: 支持嵌入原始pdf


THE END
