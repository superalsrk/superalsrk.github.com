---
title: SpringBoot-多数据源
date: 2016-03-01 11:08:36
tags: ['Java']
description: 使用AbstractRoutingDataSource来配置多个数据源
keywords: ['SpringBoot', '主从分离']
toc: true
---

# 前言

新项目使用了主从数据库, 从数据库用来查询报表数据, 主数据库用来CRUD业务数据以及定时插入报表数据, 而且项目中同时使用了 *Spring Data JPA* 和 *Mybatis* , 配置多个数据源就成了一个很繁琐的问题。

<!-- more -->

按照平常的思路, 就是一个数据源配置一个 `DataSource` , 然后对于Mybatis来讲就要配置多个 `SqlSessionFactory` , DAO和Repository都需要根据文件夹进行区分, 好了, 等你配置完直到能跑的时候就会发现, 项目已经炸了。

一种比较优雅的方法是, 对外只提供一个 `DataSource` 的虚拟中介, 在配置 `SessionFactory` / `SqlSessionFactory` 的时候用的是这个虚拟中介数据源, 等具体要用数据源的时候, 根据某个 Key值来决定到底使用哪一个数据源。 __AbstractRoutingDataSource__ 类就提供了这种功能。


# 原理

**AbstractRoutingDataSource** 的源码如下, 这个类实现了 **DataSource** 接口无误

```
public abstract class AbstractRoutingDataSource extends AbstractDataSource implements InitializingBean {
    public Connection getConnection() throws SQLException {  
        return determineTargetDataSource().getConnection();  
    } 
    public Connection getConnection(String username, String password) throws SQLException {  
        return determineTargetDataSource().getConnection(username, password);  
    }
}
```

然后具体是怎么获取 Connection的呢? **determineTargetDataSource** 具体实现是这样的

```
protected DataSource determineTargetDataSource() {  
    Assert.notNull(this.resolvedDataSources, "DataSource router not initialized");  
    Object lookupKey = determineCurrentLookupKey();  
    DataSource dataSource = this.resolvedDataSources.get(lookupKey);  
    if (dataSource == null && (this.lenientFallback || lookupKey == null)) {  
        dataSource = this.resolvedDefaultDataSource;  
    }  
    if (dataSource == null) {  
        throw new IllegalStateException("Cannot determine target DataSource for lookup key [" + lookupKey + "]");  
    }  
    return dataSource;  
}
```

好了, 重点来了, 这段代码的核心其实只有两点

+ **resolvedDefaultDataSource** : 一个 `Map<Object, DataSource>` , 就是在配置的时候手动配置的Key与数据源的对应关系
+ **determineCurrentLookupKey()** : 用来获取 Key 值, 需要在子类中实现获取Key的策略

# 思路

1. 项目中配置主从数据源, 并配置自己实现的AbstractRoutingDataSource子类做 主要的(@Primary)的DataSource
2. 实现AbstractRoutingDataSource子类, Key获取策略为从一个LocalThread变量中获取
3. 设计一个自定义注解,用于在Service层, DAO层, Repository层中使用
4. 通过AOP的方式去读取自定义注解, 然后根据注解往LocalThread里塞Key
5. 因为jetty可能会重用LocalThread, 所以需要在完成之后清空LocalThread变量, 至此, 多数据源配置完成

# 实现

首先, 写一个自定义的注解, 用在Service中的各个Method上

```
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface MzDataSource {
    String name() default MzDataSource.master;
    public static String master = "masterDataSource";
    public static String slave = "slaveDataSource";
}
```

然后再写一个类用来存放LocalThread变量

```
public class DynamicDataSourceResolver extends AbstractRoutingDataSource {
    @Override
    protected Object determineCurrentLookupKey() {
        String key =  DataSourceRouteHolder.getDataSourceKey();
        if(StringUtils.isBlank(key)) {
            return MzDataSource.master;
        }
        return key;
    }
}
```

再写一个普通风格的AbstractRoutingDataSource实现, 策略就是直接从LocalThread里直接取Key

```
public class DataSourceRouteHolder {
    private static final ThreadLocal<String> dataSources = new ThreadLocal<>();
        public static void setDataSourceKey(String customType) {
    dataSources.set(customType);
    }
    public static String getDataSourceKey() {
        return (String) dataSources.get();
    }
    public static void clearDataSourceKey() {
        dataSources.remove();
    }
}
```

使用注解AOP的方式来读取Service方法上的自定义注解, 然后塞进ThreadLocal里, 下面的实现既支持Service接口里的注解, 也支持Service实现中注解, 实现优先级大于接口

```
@Component
@Aspect
public class DataSourceAspect {
    @Pointcut("execution(* cn.stackbox.service..*(..))")
    public void aspect() {}
    @Before("aspect()")
    public void doBefore(JoinPoint point) throws Throwable {
        final MethodSignature methodSignature = (MethodSignature) point.getSignature();
        Method method = methodSignature.getMethod();
        MzDataSource mzDataSource = method.getAnnotation(MzDataSource.class);
        if(method.getDeclaringClass().isInterface()) {
            method = point.getTarget().getClass().getMethod(method.getName(), method.getParameterTypes());
        }
        mzDataSource = method.getAnnotation(MzDataSource.class);
        if(null != mzDataSource) {
            DataSourceRouteHolder.setDataSourceKey(mzDataSource.name());
        }
    }
    @After("aspect()")
    public void doAfter() {
        DataSourceRouteHolder.clearDataSourceKey();
    }
}
```

最后配置一下主从数据源, 需要注意的是需要在DynamicDataSourceResolver上加一个 `@Primary` 的注解, 不然会抛出一个类qualifier多个实例的异常

```
@Bean
@Primary
public DataSource dataSource() {
    DynamicDataSourceResolver resolver = new DynamicDataSourceResolver();
    Map<Object, Object> dataSources = Maps.newHashMap();
    dataSources.put("masterDataSource", masterDataSource());
    dataSources.put("slaveDataSource", slaveDataSource());
    resolver.setTargetDataSources(dataSources);
    return resolver;
}
@Bean
@ConfigurationProperties(prefix="spring.datasource.master")
public DataSource masterDataSource() {
    return new org.apache.tomcat.jdbc.pool.DataSource();
}
@Bean
@ConfigurationProperties(prefix="spring.datasource.slave")
public DataSource slaveDataSource() {
    return new org.apache.tomcat.jdbc.pool.DataSource();
}
```

# 注意

1. 要及时清空LocalThread变量, 防止LocalThread重用引起的错误
2. 这种方式, 在配置分布式事务的时候相当复杂, 具体参考 [此文](http://hungryant.github.io/java/2015/11/26/java-spring-boot-jta.html)

	





