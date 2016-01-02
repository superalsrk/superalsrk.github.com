---

title: Build Your Own Cas Service - Basic
date: 2015-01-06 13:21:16
tags: ['工具','Auth']
categories: ['软件工程','Auth']
description: "JASIG-CAS基础配置,以及对几个核心接口的分析"
keywords: "cas原理,cas源码分析,cas部署, cas无https配置"
---
##预备知识


具体的CAS协议见, [CAS Protocal](http://jasig.github.io/cas/4.0.x/protocol/CAS-Protocol.html),接下来我们讲jasig的CAS Implementation的几个重要的点，以下所有描述都基于版本 [3.5.2.1](http://mvnrepository.com/artifact/org.jasig.cas/cas-server-core/3.5.2.1)
<!--more-->

JASIG有以下几个比较重要的接口

+ [Credentials](https://github.com/Jasig/cas/blob/v3.5.2.1/cas-server-core/src/main/java/org/jasig/cas/authentication/principal/Credentials.java) 用户认证凭证, CAS的默认凭证只有用户名密码，所以如果想在认证的时候除了用户名密码外还要验证产品信息，就要自定义一个Credentials了，下面的Handler和Resolver都有一个support接口，用来判断是否支持处理某种类型的Credentials

+ [AuthenticationHandler](https://github.com/Jasig/cas/blob/v3.5.2.1/cas-server-core/src/main/java/org/jasig/cas/authentication/handler/AuthenticationHandler.java) 前台页面提交登录信息后，此接口判断登录信息是否能认证通过,接口会抛出一个AuthenticationException异常，用以在上层代码中catch并在前台页面显示错误信息

+ [CredentialsToPrincipalResolver](https://github.com/Jasig/cas/blob/v3.5.2.1/cas-server-core/src/main/java/org/jasig/cas/authentication/principal/CredentialsToPrincipalResolver.java) CAS-Client端与CAS-Server交互时返回结果,默认只有一个username，如果想附带其他属性，可以自己实现一个Resolver，此外，jasig提供了一些与LDAP等系统集成的Resolver，功能也十分强大

+ [AuthenticationException](https://github.com/Jasig/cas/blob/v3.5.2.1/cas-server-core/src/main/java/org/jasig/cas/authentication/handler/AuthenticationException.java) 在authentication阶段可能会抛出异常，抛出的异常信息可以前台页面中进行展示



##CAS部署与配置##
对于版本 3.5.x, 部署的war包为 module文件夹下的 __cas-server-webapp-3.5.2.1.war__

###无https配置
+ 修改 /WEB-INF/deployerConfigContext.xml， 设置安全属性
```
<bean class="org.jasig.cas.authentication.handler.support.HttpBasedServiceCredentialsAuthenticationHandler"
  p:httpClient-ref="httpClient"  p:requireSecure="false"/>
```
+ 修改 /WEB-INF/spring-configuration/ticketGrantingTicketCookieGenerator.xml
```
<bean id="ticketGrantingTicketCookieGenerator"
    class="org.jasig.cas.web.support.CookieRetrievingCookieGenerator"
    p:cookieSecure="false"
    p:cookieMaxAge="-1"  
    p:cookieName="CASTGC"
    p:cookiePath="/cas" />
 </beans>
```

+ 修改 \WEB-INF\spring-configuration\warnCookieGenerator.xm
```
<bean id="warnCookieGenerator"
    class="org.jasig.cas.web.support.CookieRetrievingCookieGenerator"
    p:cookieSecure="true"  
    p:cookieMaxAge="-1"  
    p:cookieName="CASPRIVACY"
    p:cookiePath="/cas" />
```

> 1. 参数p:cookieSecure="true"，TRUE为采用HTTPS验证，与deployerConfigContext.xml的参数保持一致。
> 2. 参数p:cookieMaxAge="-1"，简单说是COOKIE的最大生命周期，-1为无生命周期，即只在当前打开的IE窗口有效，IE关闭或重新打开其它窗口，仍会要求验证。可以根据需要修改为大于0的数字，比如3600等，意思是在3600秒内，打开任意IE窗口，都不需要验证。

THE END
