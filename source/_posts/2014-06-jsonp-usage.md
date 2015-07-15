---

title: '使用jsonp解决跨域问题'
date: 2014-06-21 17:16:00
tags: ['前端']
description: "关于jsonp的原理与使用"
keywords: "jsonp,解决跨域问题,jsonp原理，CORS"
---

首先，需要明确记住的是，jsonp不是ajax的一种特例，而是使用动态script来获取数据的一种方式。

## 原理
由于[同源策略](http://baike.baidu.com/link?url=LEaAmZN5IYfQA1MwEnUm8eIgio8sTU9lRdsvwtJKKHIuGFYxKRtOOXumMICnUHFHLyQk5kLzfyXzTm_ERmJkfK),一般来说位于 server1.example.com的网页无法与不是 server1.example.com 的服务器沟通， 而 HTML的 `<script>` 元素是个例外,利用这个策略，可以实现跨域获取数据的功能。

所以，我们只要构建一个`<script>`元素，然后将 `src` 属性赋值成我们请求资料的地址即可（参数适用get方式进行拼接），比如：

```javascript
<script type="text/javascript"
	src="http://server2.example.com/userlist?userId=1823&callback=sayHello">
</script>
```

浏览器请求这个资源，服务器端进行一些特殊的处理,给浏览器返回如下所示的资源。

```javascript
sayHello({
	'userId' : 1823,
	'name' : 'stackbox'
})
```

即全局运行了一个sayHello函数，参数为获取的json数据。

jQuery内置提供的jsonp功能,最简单的使用方式如下:

```javascript
jQuery.getJSON(url+"&callback=?", function(data) {
    alert("Symbol: " + data.symbol + ", Price: " + data.price);
});
```
此时jQuery会生成一个命名随机的callback方法， 比如 **jQuery18308848262811079621_1393981029347**，然后会
将这个函数附加到全局window，这样返回资源的时候就能调用这个函数了。


也可以指定自己的callback名，比如:

```javascript
 $.ajax({
        url:"http://localhost:20002/MyService.ashx?callback=?",
        dataType:"jsonp",
        jsonpCallback:"person",
        success:function(data){
            alert(data.name + " is a a" + data.sex);
        }
   });
```

除了使用 [$.ajax](http://api.jquery.com/jquery.ajax/),也可以使用 [$.ajaxSetup](http://www.w3schools.com/Jquery/ajax_ajaxsetup.asp)对请求进行设置。



## 示例




## 备注

JSONP是一个非标准的规范，其优点在于浏览器兼容性，而且由于发展
的比较早目前有大量基于JSONP的api(Yahoo,Twitter, etc) 和库(jQUery, YUI)
它的缺点也很明显：
1. 使得rest风格的api不再那么优雅
2. 安全问题
3. 与跨域的接口交互困难，无法post，无法直接给接口传一个json(虽然可以URLEncode成一个参数，但是比较丑陋)
4. 调试复杂，具体参见 [这篇文章](http://johnnywey.wordpress.com/2012/05/20/jsonp-how-does-it-work/)

而且，解决跨域问题的方式不止有JSONP这一种，还有 [Cross-Origin Resource Sharing (CORS)](http://zh.wikipedia.org/wiki/%E8%B7%A8%E4%BE%86%E6%BA%90%E8%B3%87%E6%BA%90%E5%85%B1%E4%BA%AB) 和 Proxy两种。

+ CORS的关键在于: XMLHttpRequest 在Level 2时新增了跨域访问的功能，需要在服务器端设置一些特殊header，兼容性你懂得。
+ Proxy方式就是： 使用apache/Nginx将另外一个site的接口映射到同源的URL下，简单暴力。缺点在于每次新的api都要修改proxy的配置。



## 后记

资料来源：

1. http://zh.wikipedia.org/wiki/JSONP
2. http://blog.csdn.net/patern_pan/article/details/7588755
3. http://forum.jquery.com/topic/jsonp-and-randomly-generated-callback-function
4. http://stackoverflow.com/questions/22186703/modifying-jquery-jsonp-callback-function
5. http://johnnywey.wordpress.com/2012/05/20/jsonp-how-does-it-work/


PS:今天在和GR童鞋谈论校长的 [《淘宝技术这十年》](http://book.douban.com/subject/24335672/) 时候, 发现这么一个知识点:

> 生成首页后，对Web前端稍微有点常识的人都应该知道，浏览器下一步会加载页面中用到的CSS、JS（JavaScript）、图片等样式、脚本和资源文件。但是可能相对较少的人才会知道，你的浏览器在同一个域名下并发加载的资源数量是有限的，例如IE 6和IE 7是两个，IE 8是6个，chrome各版本不大一样，一般是4～6个。我刚刚看了一下，我访问淘宝网首页需要加载126个资源，那么如此小的并发连接数自然会加载很久。

好了，就到这里了。

THE END
