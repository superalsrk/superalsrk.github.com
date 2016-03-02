---
title: 使用Gitlab CI进行持续集成
date: 2015-12-31 15:19:40
tags: ['工具']
description: 本地Runner对小团队来说还是挺好用的                              	
categories: ['工具']
keywords: ['Gitlab-ci', '持续集成']
toc: true
---

> 公司用的gitlab社区版, 跑CI的话需要折腾一下, 总体来说, 本地RUNNER最方便	

# 原理

在Gitlab-CI中有一个叫 `Runner` 的概念, 按照官方定义, Runner一共有三种类型

+ 本地Runner (优点:部署方便 , 缺点:使用的是开发机器的资源  MAC/WIN)
+ 普通的服务器上的Runner (优点: 没找到 , 缺点: 在RHEL系列的机器里特别难配置,至今未成功过)
+ 基于Docker的Runner (优点: 这可是Docker啊就问你怕不怕 , 缺点:至今没研究明白怎么用maven本地仓库,Build时候处理依赖极慢)


Runner安装成功之后, 就可以根据配置中的URL和Token 跟CI进行绑定, 之后这两端之间就会各种消息交互, 然后自动的Build&返回结果


# 使用

先来安装 [gitlab-ci-multi-runner](https://gitlab.com/gitlab-org/gitlab-ci-multi-runner) , 在MAC下使用最新版的 `homebrew` 安装即可, 其他系统见[官方文档](https://gitlab.com/gitlab-org/gitlab-ci-multi-runner)



```bash
$ brew update
$ brew install gitlab-ci-multi-runner

#然后启动Runner去和CI进行绑定
$ gitlab-ci-multi-runner register

#-->然后让你输入上图的CI URL
#-->然后让你输入上图的Token
#-->然后随便给Runner命名
#-->然后类型的话， 请务必选 Shell
#-->完毕

#把Runner当成Service启动
$ cd ~
$ gitlab-ci-multi-runner install
% gitlab-ci-multi-runner start
```

和 `travis-ci` 类似, 请在你的项目根目录下创建一个文件 `.gitlab-ci.yml` , 加入以下测试代码

```
build:
    script: "pwd & mvn test"
```


不出意外的话, 项目中已经有一个Build在开始跑了

# 注意事项

+ 本地Runner用的bash去构建的, 所以务必确保把环境变量配置全, 比如 `JAVA_HOME`, `PATH`




