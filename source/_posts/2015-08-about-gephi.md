---
title: Gephi简介
date: 2015-08-26 11:38:00
tags: ['算法','工具','数据开发']
description: Gephi是一款开源免费跨平台基于JVM的复杂网络分析软件, 擅长处理图数据
keywords:
toc: true
---
Gephi是一款开源免费跨平台基于JVM的复杂网络分析软件, 其主要用于各种网络和复杂系统, 特别是在处理网络关系数据这方面很有优势,下面是两个不错的例子

+ [编程语言关系图](http://exploringdata.github.io/vis/programmers-search-relations/)

![](http://7jptw8.com1.z0.glb.clouddn.com/gephi/programming-rel.png)

+ [微博传播分析](http://www.weiboreach.com/Try/exa2.jsp?val=3839629461690386_1684941721)

![](http://7jptw8.com1.z0.glb.clouddn.com/gephi/weibo.png)

那么,我们拿到图数据后, 应该如何画出这个图表呢？
## 图表绘制

通过分析上面两个例子的代码可知,前端插件用的都是 [sigma.js](http://sigmajs.org/) ,但是在展示网络数据的时候插件并不会自动的对节点和边进行布局,需要通过后台传给前台数据文件,常用的有两种格式 **json** 和 **gexf**

虽然gephi是一个gui程序,但是它提供了一套叫 **gephi-toolkit** 的东西,可以方便的编程化方式处理数据, 首先加入gephi仓库并引入依赖
```xml
<repositories>
     <repository>
            <id>gephi-snapshots</id>
            <name>Gephi Snapshots</name>
            <url>http://nexus.gephi.org/nexus/content/repositories/snapshots/</url>
     </repository>
     <repository>
            <id>gephi-releases</id>
            <name>Gephi Releases</name>
            <url>http://nexus.gephi.org/nexus/content/repositories/releases/</url>
     </repository>
</repositories>
<dependencies>
    <dependency>
            <groupId>org.gephi</groupId>
            <artifactId>gephi-toolkit</artifactId>
            <version>0.8.2</version>
    </dependency>
</dependencies>
```
添加依赖完成之后,可以参考这个 [slide](http://www.slideshare.net/gephi/gephi-toolkit-tutorialtoolkit) 熟悉一下API


## 布局算法

布局算法是图算法的一大部分, 常用的有 [Force-directed_graph_drawing
](https://en.wikipedia.org/wiki/Force-directed_graph_drawing) 力导向算法, 其基本思想是:

+ 对网络状态进行初始化
+ 计算每次迭代局部区域内，两两节点间的斥力所产生的单位位移（一般为正值）
+ 计算每次迭代每条边的引力对两端节点所产生的单位位移（一般为负值）
+ 上面两步中的斥力和引力系数直接影响到最终态的理想效果，它与节点间的距离、节点在系统所在区域的平均单位区域均有关，需要开发人员在实践中不断调整
+ 累加所有节点的单位位移，结合单次最大移动距离确定每个节点新的位置
+ 迭代n次,达到最优效果

gephi-tookit中也自带了几种布局算法, 而且易于使用, 如果你的数据源是数据库, 可以参考 [这个例子](https://github.com/gephi/gephi/wiki/How-to-import-from-RDBMS) ,当然也可以纯手工构建一个图, 示例代码如下所示:

```java
ProjectController pc = Lookup.getDefault().lookup(ProjectController.class);
pc.newProject();
Workspace workspace = pc.getCurrentWorkspace();

//Generate a new random graph into a container
Container container = Lookup.getDefault().lookup(ContainerFactory.class).newContainer();

GraphModel graphModel = Lookup.getDefault().lookup(GraphController.class).getModel();
DirectedGraph graph = graphModel.getDirectedGraph();

Node n0 = graphModel.factory().newNode("n0");
n0.getNodeData().setLabel("n0");
Node n1 = graphModel.factory().newNode("n1");
n1.getNodeData().setLabel("n1");
Edge edge = graphModel.factory().newEdge(n0, n1, 1f, true);


graph.addNode(n0);
graph.addNode(n1);
graph.addEdge(edge);


for(int i = 0 ; i < 100; i++) {
   Node ntmp = graphModel.factory().newNode("tmp" + i);
   Edge edgetmp = graphModel.factory().newEdge(n0, ntmp, 1f, true);

   graph.addNode(ntmp);
   graph.addEdge(edgetmp);
}

System.out.println("Nodes: " + graph.getNodeCount());
System.out.println("Edges: " + graph.getEdgeCount());

//Layout for 15 seconds
AutoLayout autoLayout = new AutoLayout(20, TimeUnit.SECONDS);
autoLayout.setGraphModel(graphModel);
YifanHuLayout firstLayout = new YifanHuLayout(null, new StepDisplacement(1f));
ForceAtlasLayout secondLayout = new ForceAtlasLayout(null);
AutoLayout.DynamicProperty adjustBySizeProperty = AutoLayout.createDynamicProperty("forceAtlas.adjustSizes.name", Boolean.TRUE, 0.1f);//True after 10% of layout time
AutoLayout.DynamicProperty repulsionProperty = AutoLayout.createDynamicProperty("forceAtlas.repulsionStrength.name", new Double(500.), 0f);//500 for the complete period
autoLayout.addLayout(firstLayout, 0.9f);
autoLayout.addLayout(secondLayout, 0.1f, new AutoLayout.DynamicProperty[]{adjustBySizeProperty, repulsionProperty});
autoLayout.execute();

//Export pdf & gexf
ExportController ec = Lookup.getDefault().lookup(ExportController.class);
try {

    File pdfFile = new File("/tmp/data.pdf");
    File gexfFile = new File("/tmp/data.gexf");

    pdfFile.getParentFile().mkdirs();
    gexfFile.getParentFile().mkdirs();
    ec.exportFile(pdfFile);
    ec.exportFile(gexfFile);
} catch (IOException ex) {
    ex.printStackTrace();
}
```
其中导出的 **gexf** 数据文件可以用于 sigmajs的展示

## 参考资料
1. http://gephi.github.io/
2. http://www.slideshare.net/gephi/gephi-toolkit-tutorialtoolkit
3. https://github.com/gephi/gephi/wiki/How-to-code-with-the-Toolkit

THE END
