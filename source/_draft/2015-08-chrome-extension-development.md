---
title: 编写一个chrome插件
date: 2015-08-13 15:37:58
tags: ['前端']
description: "从0到1编写一个chrome插件"
keywords:
---

最近需要写一个chrome的插件方便PM使用,最终需要实现的功能有以下几点:
1. 刷新页面的时候替换特定的js
2. 点击popup页面的按钮触发页面中的js方法
3. 监听http请求并打印

## 基础框架



```bash
$ npm install -g generator-chrome-extension
$ mkdir YOUR_EXTENSION & cd YOUR_EXTENSION

#在当前文件夹创建插件
$ yo chrome-extension
```
## 插件组成

+ manifest.json
+ popup page
+ config page
+ 在chrome插件里, 有三种类型的脚本,他们有不同的上下文环境以及不同的Chrome API权限
    + **Background Script:**
    + **Context Script:**
    + **Inject Script:**


## 消息传递

在如何触发全局函数这块,走了些弯路, 一开始准备用 `executeScript`方法来直接执行函数, 其中MyFunc是页面引入的js中定义的
```javascript
chrome.tabs.getSelected(null, function(tab) {
        chrome.tabs.executeScript(tab.id, {action: details.url, type:'http'}, MyFunc);
})
```
But..真的这样写的话,会报 `MyFunc not defined`错误, 核心原因是JS上下文环境不同。



## 网络监听
