---
title: SpringBoot-日志相关
date: 2016-03-02 19:49:26
tags: ['SpringBoot']
description: SpringBoot中关于Logback使用的一些tips
keywords: ['SpringBoot', 'SLF4J', 'springprofile logback']
toc: true
---


## 基础使用

SpringBoot提供了一套基本的日志系统, 默认是基于 Logback+SLF4J, 最基本的配置文件如下

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <include resource="org/springframework/boot/logging/logback/base.xml" />
	<!-- 用来显示mybatis的sql -->
    <logger name="cn.stackbox.mapper" level="DEBUG"/>

</configuration>
```

其中 `base.xml` 的代码如下

```
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <include resource="org/springframework/boot/logging/logback/base.xml" />

    <root level="info">
        <appender-ref ref="CONSOLE" />
        <appender-ref ref="FILE" />
    </root>

    <logger name="cn.stackbox.mapper" level="DEBUG"/>

</configuration>
```

可以看到springboot已经定义了基本的 ROOT-LOGGER, CONSOLE-APPENDER, FILE-APPENDER


## Spring整合

可以使用spring来扩展profile的支持, 必须以 **logback-spring.xml** 命名

```
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <include resource="org/springframework/boot/logging/logback/base.xml" />
    <logger name="org.springframework.web" level="INFO"/>
    <logger name="org.springboot.sample" level="TRACE" />

    <springProfile name="dev">
        <logger name="org.springboot.sample" level="DEBUG" />
    </springProfile>

    <springProfile name="staging">
        <logger name="org.springboot.sample" level="INFO" />
    </springProfile>

</configuration>
```

## 日志分割

可以用如下代码进行日志分割

```
<appender name="MZRollingFileAppender" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <File>/home/data/superalsrk/SLF4J/stackbox-eureka/eureka.log</File>
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
        <FileNamePattern>/home/data/superalsrk/SLF4J/stackbox-eureka/eureka.%d{yyyy-MM-dd}.log</FileNamePattern>
        <maxHistory>3000</maxHistory>
    </rollingPolicy>
    <encoder>
         <Pattern>%d{YYYY-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{35} - %msg %n</Pattern>
    </encoder>
</appender>
```

## 一些扩展

目前我的需求是

+ 线上会有Rolling日志, 放到磁盘的某个特殊位置
+ 本地Console即可

所以我的脚本为

```
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <include resource="org/springframework/boot/logging/logback/base.xml" />

    <springProfile name="production">
        <appender name="STBRollingFileAppender" class="ch.qos.logback.core.rolling.RollingFileAppender">
            <File>/home/data/superalsrk/SLF4J/stackbox-eureka/eureka.log</File>
            <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
                <FileNamePattern>/home/data/superalsrk/SLF4J/stackbox-eureka/eureka.%d{yyyy-MM-dd}.log</FileNamePattern>
                <maxHistory>3000</maxHistory>
            </rollingPolicy>
            <encoder>
                <Pattern>%d{YYYY-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{35} - %msg %n</Pattern>
            </encoder>
        </appender>
    </springProfile>


    <springProfile name="development">
        <root level="INFO">
            <appender-ref ref="CONSOLE" />
        </root>
    </springProfile>

    <springProfile name="production">
        <root level="INFO">
            <appender-ref ref="CONSOLE" />
            <appender-ref ref="STBRollingFileAppender" />
        </root>
    </springProfile>

</configuration>
```

然后在 `application.yml` 里设置一下默认 **Profile**

```
spring:
  profiles:
    default: production
```

这样不加参数的时候就会用 `production` 这个Profile,然后为了让 IDE使用 `development`, 可以加入一个 Program arguments(还有其他设置Profile的方法)

```
--spring.profiles.active=development
```



