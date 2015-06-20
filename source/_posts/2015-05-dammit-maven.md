---

title: maven大坑
date: 2015-05-11 00:53:31
tags: ['软件工程']
description: "Damn it,maven！"
keywords: "MAVEN注意点"
toc: true
---


## 乱码

再部署某产品的时候, 出现了诡异的编码错误,主要体现为:

+ 登陆提交的表单会自动加一串奇奇怪怪的乱码
+ Constant变量中的中文在当成message放在json中也会出现乱码

一开始我以为是Linux的Locale环境变量引起的,但是改之依然没有效果,而从上面的那个第二条大致可以
猜出是文件编译的时候把encoding搞乱了。因为@FanFan童鞋用直接eclipse的export导出的war是可用的,那就是说打包的时候错误了。

最后的解决方法是: ** pom.xml配置编码方式 **

先配置:

```xml
<properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding> 
</properties>
```

然后再配置 maven-compiler-plugin

```xml
<plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.1</version>
        <configuration>
            <source>1.7</source>
            <target>1.7</target>
            <encoding>UTF-8</encoding> 
        </configuration>
</plugin>
```

## mybatis代理失效

这个问题找的比较快,因为mybatis是通过动态代理模式来实现DAO接口的, 一看到CGLib失败就知道接口的代理出现了问题。
果不其然，在编译的结果里没有找到mybatis的xml。

好吧，项目的先人把XML放到了 `src/main/java` 下, 而默认会忽略掉这个文件夹下的配置文件的。而且先人还是通过eclipse->export导出war包的，所以就没有发现这个问题。

解决方法:
+ 比较暴力的方法是把xml,properties 都放到`src/main/resources`下
+ 本着较少改动的原则,给pom.xml添加如下配置

```
 <resources>
    <resource>
        <directory>src/main/resources</directory>
        <filtering>true</filtering>
    </resource>
    
    <resource>
        <directory>src/main/java</directory>
        <includes>
            <include>**/*.xml</include>
            <include>**/*.properties</include>
        </includes>
        <filtering>true</filtering>
    </resource>
</resources>
```

注意,如果不加`<includes>`会把java文件也打进package。。orz

## 其他
配xml不能随便，不能随便
