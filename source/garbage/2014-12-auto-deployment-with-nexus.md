---

title: 利用Nexus和Shell进行自动化部署
date: 2014-12-01 16:50:54
tags: ['运维']
description: "通过使用nexus进行java web项目的部署"
keywords: "maven,nexus,maven自动部署"
---

项目部署工作是一个很无聊，很费时，但又十分重要的工作，记得在飞饭的时候，由于项目并没有采用maven构建，以及项目包含了
大量的图片，部署工作很是麻烦，当是只是在测试的时候采用 ｀git hook` 的方式半自动化运维。

实际在运维的时候，稍微麻烦的项目可以采用jenkins，bamboo，puppet，不过由于目前dashboard还算一个很小的项目，
就采用了shell＋nexus仓库的方式进行部署。

<!--more-->

思路如下：
1. `mvn deploy` 发布war包到nexus
2.  调用nexus的接口获取某个版本的war包
3.  scp上传至服务器，并远程调用shell进行清理，解压缩，重启tomcat等操作

注意点如下:
1.  使用spring profile来区分development和production环境
2.  远程启动tomcat的时候,需要export tomcat启动所需的环境变量



__auto_dploy.sh__
```bash
#!/bin/sh
CURRENT_DIR=`pwd`

function init_localrepo() {
     rm -rf /tmp/dashboard;
     mkdir /tmp/dashboard;
     cd /tmp/dashboard;
     $(wget "http://192.168.10.61:9091/nexus/service/local/artifact/maven/content?g=com.miaozhen&a=dashboard&v=LATEST&r=snapshots&p=war&v=0.0.1-SNAPSHOT" -O target.war)
     scp target.war demo@example.com:/home/supertool/lvsijia/apache-tomcat-7-demo/webapps/ROOT
}

init_localrepo;
cd $CURRENT_DIR
ssh supertool@56.mzhen.cn "bash -s" <  server_deploy.sh
```


__server_deploy.sh__
```bash

#!/bin/sh
DEPLOY_DIR=/home/YOURFOLDER/apache-tomcat-7-demo/webapps/ROOT
TOMCAT_DIR=/home/YOURFOLDER/apache-tomcat-7-demo/bin

cd $DEPLOY_DIR;

rm -rf assets
rm -rf META-INF
rm -rf WEB-INF
rm index.jsp

unzip target.war
rm target.war

#强制kill掉tomcat进程
ps ax|grep tomcat-7-demo | awk '{print $1}' |xargs kill -9;

cd $TOMCAT_DIR ;

export CATALINA_BASE=/home/supertool/lvsijia/apache-tomcat-7-demo
export CATALINA_HOME=/home/supertool/lvsijia/apache-tomcat-7-demo
export CATALINA_TMPDIR=/home/supertool/lvsijia/apache-tomcat-7-demo/temp
export JRE_HOME=/usr/java/jdk1.7.0_05
export CLASSPATH=/home/supertool/lvsijia/apache-tomcat-7-demo/bin/bootstrap.jar:/home/supertool/lvsijia/apache-tomcat-7-demo/bin/tomcat-juli.jar

bash startup.sh;
```