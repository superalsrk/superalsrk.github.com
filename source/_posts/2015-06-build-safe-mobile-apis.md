---
title: 构建安全的Mobile API
date: 2015-06-27 23:30:46
tags: ['软件工程','Java','Spring']
categories: ['软件工程','实践']
description: '讲解如何对REST接口进行访问控制'
keywords:
toc: true
---

最近和小伙伴鼓捣一个APP, 没想到一开始在登陆注册这块就卡住了, 卡住的原因在于 __如何对接口进行访问控制__ , 大家都知道, 在传统的web开发中由于有session/cookie的存在,请求可以保持状态, 但一般来讲,APP用到的API都是被设计成无状态的, 那应该如何解决问题呢?

## 解决思路

+ 对于平台类API来说,其目标用户一般是开发者, 诸如[饿了么OpenApi](http://openapi.eleme.io/v2/quickstart.html)或者 [Pusher.com](https://pusher.com/docs/rest_api#authentication) 这类服务,每次调用都是独立的, 无需保存状态信息, 数据权限和功能权限可以通过 __AppId__ 这类唯一标识符来进行区分。安全上通过 __auth_signature__ 的方式来进行校验。具体算法可以参见上面提到的两个文档。

+ 如果目标对象是那些APP, 怎么办呢? , 刚工作那会解决这种需求的方法十分暴力:把用户名密码保存在app本地,调用接口的时候把用户名密码传过去做校验, 没有优雅性可言。目前来讲,在写Mobile API时, 直接使用 __Oauth2__ 来处理权限问题是一种比较常用的方法。__Oauth2__ 看起来略复杂,但其最终目的是获取一个 __访问令牌__ , 获取令牌的模式一共有四种.

> 1. 授权码: 例子有微博第三方登陆,流程为: 第三方网站 -> 跳转到微博让用户选择是否授权 -> 用户授权并通过回调返回第三方一个授权码 -> 第三方根据授权码向微博申请访问令牌 -> 微博返回访问令牌
> 2. 隐式授权: 流程为: 跳转到授权页面 -> 授权成功之后回调返回访问令牌
> 3. 密码模式: 流程为: 发送一个带用户名密码参数的请求([并附带Http Basic Authorization](http://www.cnblogs.com/pengyingh/articles/2377968.html)) -> 返回一个访问令牌
> 4. 客户端模式: 这个方式很有意思,在这种模式下, 是以客户端的名义而不是以用户的名义进行令牌申请, 权限上并没有区分,也就不存在授权问题了, 流程为: 向认证服务器发起请求 -> 以某种方式验证客户端的方式(比如根据appId,appSecret) -> 返回访问令牌

如果是编写Mobile API, 密码模式是一种比较简单的选择: 这样,登录过程就变成了获取令牌的过程,登录成功之后把令牌存到本地,之后的API调用带上令牌即可。

## 工程实践

对于NodeJs开发者来说, 由于有 __passport.js__及一众package的存在, 编写一个 __受不记名访问令牌保护的API__ 十分的简单, 可以参考 [这篇教程](http://aleksandrov.ws/2013/09/12/restful-api-with-nodejs-plus-mongodb/#Step1) 搭建基础环境。 下面的内容是在java环境中使用spring-security-oauth2+springmvc的工程实践。

不得不说,采用 Annotation 方式配置spring是一种非常好的实践, 可读性上比XML强太多, 详细配置请参考 [示例项目](https://github.com/Nagland/spring-security-rest-with-oauth2)

+ 配置spring-security


```java
@Configuration
@EnableWebSecurity
public class WebSecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        auth
                .inMemoryAuthentication()
                .withUser("user").password("password").roles("USER").and()
                .withUser("stackbox").password("123456").roles("ADMIN");
    }

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
                .csrf().disable();
    }

    /**
     * 这个Bean用于oauth2的密码授权模式的配置
     */
    @Override
    @Bean
    public AuthenticationManager authenticationManagerBean() throws Exception {
        return super.authenticationManagerBean();
    }
}
```
一般来讲spring-security还要加个过滤器,通过加入下面这个类,就能够不配置web.xml来加入过滤器了。
```java
public class SpringSecurityInitializer extends AbstractSecurityWebApplicationInitializer{

}
```
+ 配置oauth2

[项目文档](http://projects.spring.io/spring-security-oauth/docs/oauth2.html) 里讲了几个核心接口,参照例子, 我们同样采用注解的方式进行配置。在代码里可以通过 `@EnableResourceServer` 来配置资源服务器, 资源服务器的配置和spring-security的权限配置十分类似,`@EnableAuthorizationServer` 来配置认证服务器。注意在文档中有这么一句话。

> The grant types supported by the AuthorizationEndpoint can be configured via the AuthorizationServerEndpointsConfigurer. By default all grant types are supported except password (see below for details of how to switch it on). The following properties affect grant types:

也就是说,如果要用密码授权方式的话,需要注入一个 `authenticationManagerBean` , 它就是在上面spring-security配置中的那个bean。

```java
@Configuration
public class Oauth2ServerConfig {

    protected static final String RESOURCE_ID = "STACKBOX";

    @Configuration
    @EnableResourceServer
    protected static class ResourceServer extends ResourceServerConfigurerAdapter {
        @Override
        public void configure(HttpSecurity http) throws Exception {
            http
                    .requestMatchers().antMatchers("/admin/**").and()
                    .authorizeRequests()
                    .anyRequest().access("#oauth2.hasScope('read')");
        }

        @Override
        public void configure(ResourceServerSecurityConfigurer resources) throws Exception {
            resources.resourceId(RESOURCE_ID);
        }
    }

    @Configuration
    @EnableAuthorizationServer
    protected static class AuthorizationServer extends AuthorizationServerConfigurerAdapter {

        private TokenStore tokenStore = new InMemoryTokenStore();

        @Autowired
        @Qualifier("authenticationManagerBean")
        private AuthenticationManager authenticationManager;

        @Override
        public void configure(AuthorizationServerSecurityConfigurer oauthServer) throws Exception {

            /**
             * allow表示允许在认证的时候把参数放到url之中传过去
             * @see org.springframework.security.oauth2.provider.client.ClientCredentialsTokenEndpointFilter
             */
            oauthServer.allowFormAuthenticationForClients();
        }

        @Override
        public void configure(AuthorizationServerEndpointsConfigurer endpoints) throws Exception {
            //endpoints.tokenStore(tokenStore).authenticationManager(authenticationManager);
            endpoints.tokenStore(tokenStore).authenticationManager(authenticationManager);
        }

        @Override
        public void configure(ClientDetailsServiceConfigurer clients) throws Exception {
            clients.inMemory().withClient("client")
                    .authorizedGrantTypes("password","refresh_token")
                    .authorities("ROLE_USER")
                    .scopes("read")
                    .resourceIds(RESOURCE_ID)
                    .secret("secret").accessTokenValiditySeconds(3600);
        }
    }
}

```

## 其他策略

+ **JWT(Json Web Tokens)** 目前还是一份草案, 与Oauth2项目在服务器端配置上更简单些,目前在一些使用 Angular, Ember的单页面应用中已经被使用。JWT在passport和spring-security中都能够支持。

+ **CAS for Mobile**, CAS是一个在写web项目时常用的单点登录服务器, 它也能够支持[Rest API](https://wiki.jasig.org/display/casum/restful+api) ,不过在客户端的处理比较麻烦,不过已经有了第三方的repo能够支持移动端CAS [Android](https://github.com/justindancer/android-cas-client) / [iOS](https://github.com/acu-dev/objc-cas-client)

## 参考资料
1. http://www.ruanyifeng.com/blog/2014/05/oauth_2_0.html
2. http://www.cnblogs.com/smarterplanet/p/4088479.html?utm_source=tuicool
3. http://www.cnblogs.com/pengyingh/articles/2377968.html
4. http://haomou.net/2014/08/13/2014_web_token/

> 最后再次感慨下NodeJS开发者真幸福！！！
