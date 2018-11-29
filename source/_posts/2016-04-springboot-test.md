---
title: SpringBoot-单元测试
date: 2016-04-25 16:24:45
tags: ['Java']
description: 在基于SpringBoot的项目中使用单元测试
keywords: ['SpringBoot单元测试']
---

对Controller层进行测试的时候, 如果是测试 REST接口, 使用 [rest-assured](https://github.com/jayway/rest-assured) 是一个十分不错的选择


+ 单元测试的配置与以前基于XML的项目差不错
+ 如果写了多个TestCase文件, 为了使得他们公用一个SpringContext, 应该写一个抽象类来进行测试相关的配置, 然后其他的TestCase类继承自这个抽象类即可
+ 由于测试启动Context(如果带mvc)是启动了随机的接口, 在setUp阶段需要给 rest-assured 设置一下使用的端口


### 示例代码

```
@RunWith(SpringJUnit4ClassRunner.class)
@SpringApplicationConfiguration(classes = MyApplication.class)
@WebAppConfiguration
@IntegrationTest("server.port:0")
@ActiveProfiles("test")
public abstract class AbstractTestCase {
	/**
	 * mvctest启动的随机端口号
	 */
	@Value("${local.server.port}")   //
	protected int port;
}
```

```
public abstract class AbstractRouteTestCase extends AbstractTestCase {
    /**
     * 初始化MVC TEST
     * 1. 设置RestAssured绑定端口
     * 2. 可以完成一些其他的操作
      */
    protected void initMVC() {
        RestAssured.port = port;
    }
}
```


```
public class RouterWxapiStatusTest extends AbstractRouteTestCase {
    @Before
    public void setUp() {
        initMVC();
    }
    @Test
    public void testController() {
    	JSONObject params = new JSONObject();

    	//更多语法可以详见rest-assured的wiki
    	given().header("Content-Type", "application/json")
                .header("Origin", "http://baidu.com")
                .header("Authorization", "Bearer testtoken").body(params.toJSONString())
                .when().post("/test/api").then().log().all()
                .statusCode(HttpStatus.SC_OK)
                .body("status", equalTo(200))
                .body("data.items.size()", not(0));
    }
}
```


## Update

从1.4.0(目前尚未Stable)开始, 单元测试的使用方式有一些变化, 新增了 `@WebMvcTest` ,`@SpringBootTest`,`SpringRunner`, 对TestNG的支持也做一些优化

+ [1.4.0基于Junit4的单元测试](https://github.com/spring-projects/spring-boot/tree/master/spring-boot-samples/spring-boot-sample-test/src/test/java/sample/test)
+ [1.4.0基于TestNG的单元测试](https://github.com/spring-projects/spring-boot/blob/master/spring-boot-samples/spring-boot-sample-testng/src/test/java/sample/testng/SampleTestNGApplicationTests.java) 


