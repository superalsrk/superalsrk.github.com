---

title: 如何编写一个JS库
date: 2014-12-17 20:38:24
tags: ['前端']
description: "实现JS Library常用的几种方式"
keywords: "js模式,javascript模版,javascript设计模式"
toc: true
---
编写js/jQuery插件有一些约定俗成的套路，根据这些套路依葫芦画瓢，代码的结构上就不会出现太大的问题了，特别推荐这个叫 [javascript-patterns](https://github.com/shichuan/javascript-patterns/) 的项目,一些demo让我收获良多。

## 基本结构 ##
### 普通的库 ###

用最基本的匿名函数实现即可

```
(function(){
	var root = this;
	root.YOURLIB = function(){
		FUNC1 : function(){},
		FUNC2 : function(){}
	}
}())

```

也可以使用`call`而不是使用闭包，此时两种写法等效，__undersocre.js__用的是call写法


```
(function(){
	var root = this;
	root.YOURLIB = function(){
		FUNC1 : function(){},
		FUNC2 : function(){}
	}
}.call(this))

```
### jQuery 插件###

通过一下方法可以使的插件可以 跨CMD/AMD/Browser

```javascript
(function (factory) {
	if (typeof define === 'function' && define.amd) {
		// AMD
		define(['jquery'], factory);
	} else if (typeof exports === 'object') {
		// CommonJS
		factory(require('jquery'));
	} else {
		// Browser globals
		factory(jQuery);
	}
}(function ($) {

	$.fn.render = function() {}
	$.render2 = function() {}
}))

```
当然,如果不考虑Seajs,RequireJS的话,最方便的还是使用匿名函数，然后把window.jQuery当成参数传进去

## 内部组织 ##

我们以 [bootstrap-select v1.6.3](https://github.com/silviomoreto/bootstrap-select/blob/master/js/bootstrap-select.js),[smooth-scroll](https://github.com/cferdinandi/smooth-scroll)这俩项目来进行分析，

### 初始化###

一般的Library都会提供一套defaults配置文件，然后使用的时候和用户自定义的settings进行extend, __smooth-scroll__中的那种

`settings = extend(defaults, options ||{}));` 写法就相当赞，_可以以一种十分简单的方式防止空指针异常_。

剩下的就是根据业务划分业务的funciton了，对于如何划分，只有多加练习了。

另外，在注释里像写上 __private__ 和 __public__ 来区分对外接口和对内接口是个不错的习惯。

### i18n与配置管理###

i18n是吧那些国际话的字符全都放到defautls，比较优雅的做法是defaults定义一个对象，这样国际化文件
便能和原有的库文件进行分离，具体参考 [bootstrap-datapicker]()
