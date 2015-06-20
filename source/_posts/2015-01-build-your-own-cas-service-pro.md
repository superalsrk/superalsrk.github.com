---

title: Build Your Own Cas Service - Pro 
date: 2015-01-06 13:21:17
tags: ['工具']
description: "对JASIG-CAS进行页面和业务的扩展具体步骤"
keywords: "cas自定义登陆,cas自定义Credentials,cas修改页面,cas单点退出,cas获取多余属性,cas获取更多用户信息"
---
示例代码: https://github.com/superalsrk/modify-jasig-cas ,以下所有描述都基于版本 [3.5.2.1](http://mvnrepository.com/artifact/org.jasig.cas/cas-server-core/3.5.2.1)

<!--more-->

##Generally Design
我们可以把一个war项目作为dependency，然后创建一个web项目webapp，然后只要将创建项目的 web.xml 和 index.jsp 去掉, 整个项目就能跑了。

更重要的是，如果要对war进行扩展, 只要讲war对应的文件拷贝一份到webapp，打包的时候便能自动到替换。下面讲的 **修改XXX文件**, 都是对其拷贝进行修改,特此声明:

webapp module的pom为[pom.xml](https://github.com/superalsrk/modify-jasig-cas/blob/master/webapp/pom.xml)
##Auth Module

### 自定义Credentials

Credentials是一个用户凭证, 可以理解为一个简易的pojo, 只要实现Credentials接口即可，我们的自定义凭证中除了用户名密码，还加了一个字段 product : String, 表明要登录的产品类型

在Web Module中，需要进行如下修改

1 . 在登录表单增加product字段,具体操作详见下个Section
2 . 在 /WEB-INF/login-webflow.xml 中,修改credentials类型为自定义的Credentials
```
<var name="credentials" class="com.nbrc.sso.cas.principal.NbrcCredentials"/> 
```
3 . 然后继续在 login-webflow.xml里找到 viewLoginForm ,进行数据绑定
```
<view-state id="viewLoginForm" view="casLoginView" model="credentials">  
       <binder>  
           <binding property="username" />  
           <binding property="password" />  
           <binding property="product"/> <!--增加这一行 -->  
       </binder>  
       ...  
</view-state>  
```
### 自定义Handler
自定义Handler只要实现接口 AuthenticationHandler 即可

1 . 如果要在前台显示一个 权限不足 的信息, 只需在Handler里throw一个自定义的 AuthenticationException 即可
2 . support 接口用来声明handler是否支持某种类型的凭证
3 . 修改 /WEB-INF/deployConfigContext.xml ，进行handler的配置
```
<property name="authenticationHandlers">
            <list>
                <bean
                    class="org.jasig.cas.authentication.handler.support.HttpBasedServiceCredentialsAuthenticationHandler" 
                    p:httpClient-ref="httpClient" p:requireSecure="false" />

                <bean
                    class="com.miaozhen.dashboard.darkportal.mechanism.DarkportalAuthenticationHandler" />
            </list>
</property>
```

### 自定义Resolver
Resolver是一个Credentials 到 Principal的转换器， 其中Principal其实是javaEE中就已经定义好的

1 . 修改 /WEB-INF/deployConfigContext.xml ，进行Resolver的配置
```
<property name="credentialsToPrincipalResolvers">
            <list>
                <bean
                    class="com.miaozhen.dashboard.darkportal.mechanism.DarkportalCredentialsToPrincipalResolver">

                </bean>

                <bean
                    class="org.jasig.cas.authentication.principal.HttpBasedServiceCredentialsToPrincipalResolver" />
            </list>
</property>
```
2 . resolver可以返回一个Principal, 个人觉得比较好用的方式是返回一个 #SimplePrincipal# ,除了用户的user信息外，还可以返回一个 AttrMap，不过需要参考下章进行Resolver视图的修改
```java
Map<String, Object> map = new HashMap<String, Object>();
map.put(ATTR_USERNAME, mzCredentials.getUsername());
map.put(ATTR_PASSWORD, mzCredentials.getPassword());

SimplePrincipal simple = new SimplePrincipal(mzCredentials.getUsername(), map);
```

##Web Module

### 自定义登陆页面
正常的做法应该是copy一份defaults文件夹，然后在resources里copy对应的主题配置文件，最后在cas.properties里配置一下主题，不过为了省事直接改defaults里的文件就可以了

default/ui/casLoginView.jsp 就是默认的登录界面，可以给form表单增加多余的字段。需要注意的是：form表单里还有一堆cas自带的input，这个在改页面的时候不能删掉。
<br/>
### 自定义返回用户信息
1 . 在resolver中虽然返回了更多Attr，不过默认的Resolver视图不支持返回更多属性，需要对 protocol/2.0/casServiceValidationSuccess.jsp 页面进行扩展.
```xml
<%@ page session="false"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>
<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
    <cas:authenticationSuccess>
        <cas:user>${fn:escapeXml(assertion.chainedAuthentications[fn:length(assertion.chainedAuthentications)-1].principal.id)}</cas:user>
        <c:if
            test="${fn:length(assertion.chainedAuthentications[fn:length(assertion.chainedAuthentications)-1].principal.attributes) > 0}">
            <cas:attributes>
                  <c:forEach var="attr" items="${assertion.chainedAuthentications[fn:length(assertion.chainedAuthentications)-1].principal.attributes}"> 
                    <cas:${fn:escapeXml(attr.key)}>${fn:escapeXml(attr.value)}</cas:${fn:escapeXml(attr.key)}> 
                </c:forEach> 
            </cas:attributes>
        </c:if>
        <c:if test="${not empty pgtIou}">
            <cas:proxyGrantingTicket>${pgtIou}</cas:proxyGrantingTicket>
        </c:if>
        <c:if test="${fn:length(assertion.chainedAuthentications) > 1}">
            <cas:proxies>
                <c:forEach var="proxy" items="${assertion.chainedAuthentications}" 
                    varStatus="loopStatus" begin="0" 
                    end="${fn:length(assertion.chainedAuthentications)-2}" step="1">
                    <cas:proxy>${fn:escapeXml(proxy.principal.id)}</cas:proxy>
                </c:forEach>
            </cas:proxies>
        </c:if>
    </cas:authenticationSuccess>
</cas:serviceResponse>
```
2 . 在client端，使用如下代码就可以获取多余属性
```
AttributePrincipal attribute = (AttributePrincipal) request.getUserPrincipal();
AttributePrincipal.getName()  就是 Resolver中返回的SimplePrincipal名字
AttributePrincipal.getAttributes() 就是Resolver中返回的SinmplePrincipal的attributes
```
3 . 注意把deployerConfigContext.xml中 serviceRegistryDao全部删掉(cas),[参考资料](http://www.open-open.com/lib/view/open1329744257937.html)

<br/>

### CAS退出功能
默认的JASIG退出成功后会跳到一个 推出成功页面, 但我们想要的效果是退出CAS，并且退出已经登录的应用, 那么可以进行如下的配置：

1. 如果只是退出应用，那么在此访问页面的时候，cas-client又会向cas-server端进行请求验证,然后自动登录,所以同时退出cas和应用即可
2. 修改 cas-servlet.xml , 在 logoutController 的bean中增加属性 p:followServiceRedirects="true"
3. 假如应用已经有一个退出controller，此contoller用来清空session,那么链接 http://cas.example.org/logout?service=http://localhost:8080/logout 便可以正常退出



