---
title: 使用CasperJS生成长图片
date: 2017-01-27 18:33:00
tags: ['工具']
description: 用CasperJS对网页进行截图, 并处理CentOS下的字体渲染问题
keywords: ['工具','生成长图片','PhantomJS网页截图']
---

最近有一个类似 **生成微博长图片** 类似的需求, 实现思路就是用类似PhantomJS的这种无GUI浏览器访问网页并截图


## CasperJS

CasperJS是一个基于PhantomJS的工具套件, 相比原生的PhantomJS使用起来更人性化, 比如可以通过下面的代码来对网页截图


```javascript
var casper = require('casper').create();
casper.start().thenOpen('http://card.zrank.cn/card?room_key=yizhibo_24752948&share=1', function() {
        this.capture('demo.png')
})
```

为了获取移动端浏览器下的渲染效果, 需要给CasperJS/PhantomJS加上[ViewPort](https://github.com/enesser/phantom-capture/blob/master/lib/devices.js), 例如

```javascript
var casper = require('casper').create({
      viewportSize: {
        name: 'Apple iPhone 6',
        active: true,
        width: 375,
        height: 627,
        userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 8_0 like Mac OS X) AppleWebKit/600.1.3 (KHTML, like Gecko) Version/8.0 Mobile/12A4345d Safari/600.1.4'
    }
});
```

大家都知道iPhone用的是Retina屏幕, 虽然分辨率真的是 635 * 375 , 可是如果真的用这个分辨率截图, 最终效果真心惨不忍睹, 解决方法很简单: 分辨率加一倍, 浏览器视角缩小一倍, 这样截图就清晰很多了

```javascript
var casper = require('casper').create({
      verbose: true,
      logLevel: "debug",
      viewportSize: {
        name: 'Apple iPhone 6',
        active: true,
        width: 375 * 2 ,
        height: 627 * 2,
        userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 8_0 like Mac OS X) AppleWebKit/600.1.3 (KHTML, like Gecko) Version/8.0 Mobile/12A4345d Safari/600.1.4'
    }
});

casper.start().zoom(2).thenOpen('http://stackbox.cn', function() {
        this.echo(this.getTitle())
        this.capture('demo.png')
})
```

## 字体问题

当把程序部署在服务器上时, 发现截图无法渲染字体, 想一想也是, 毕竟服务器上压根就没有安装那些字体, 能渲染出来就有鬼了

一开始的时候参照某些方法用的是 `bitmap-fonts bitmap-fonts-cjk`, 非常丑, 直接老老实实安装网页中依赖的ttf字体即可

```bash
$ sudo yum install fontconfig
$ yum remove bitmap-fonts bitmap-fonts-cjk  
$ mkdir /usr/share/fonts/custom
$ cp *.ttf  /usr/share/fonts/custom
$ fc-cache -fv
```

至于如何知晓网页依赖的字体? 打开开发者工具运行一下 `$('body').css("font-family")` 就可以了 [效果截图](http://ojwx27vxt.bkt.clouddn.com/screenshot/20170127/yizhibo-24752948-1485514066098.png)


