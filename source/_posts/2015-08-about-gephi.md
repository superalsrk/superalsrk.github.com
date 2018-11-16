---
title: 使用Gephi生成网络图
date: 2015-08-26 11:38:00
tags: [工具']
description: Gephi是一款开源免费跨平台基于JVM的复杂网络分析软件, 擅长处理图数据
keywords: ['传播路径图', '图软件', 'Gephi']
toc: true
---

## 前言
Gephi是一款开源免费跨平台基于JVM的复杂网络分析软件, 其主要用于各种网络和复杂系统, 特别是在处理网络关系数据这方面很有优势,下面是两个不错的例子

+ [编程语言关系图](http://exploringdata.github.io/vis/programmers-search-relations/)

![](http://7jptw8.com1.z0.glb.clouddn.com/gephi/programming-rel.png)

+ [微博传播分析](http://www.weiboreach.com/Try/exa2.jsp?val=3839629461690386_1684941721)

![](http://7jptw8.com1.z0.glb.clouddn.com/gephi/weibo.png)

那么,我们拿到原始数据后, 怎么才能画出这样的图表呢？

## 布局文件生成

通过上面两个例子可以分析出,这类图表可以通过 [sigma.js](http://sigmajs.org/) 画出来,但是插件本身并不提供预处理数据&&布局功能,所以在绘制图表的时候需要有一份数据文件来详细的表明`节点名称,颜色,大小,横坐标, 纵坐标,边的起始节点`,这类数据一般用 gexf(xml格式) 或者 json来表示. 

生成gexf需要用到布局算法, 常见的有 [Force-directed_graph_drawing](https://en.wikipedia.org/wiki/Force-directed_graph_drawing) 力导向算法, `算法的核心思想是节点之间产生斥力,边给两个节点提供拉力,通过多次迭代最后维持一个稳定状态`，手动实现布局算法还是有一些复杂度的,好在gephi-tookit组件提供了API来处理数据, 首先在maven项目中加入gephi的仓库和依赖
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
添加依赖完成之后,参考这个 [slide](http://www.slideshare.net/gephi/gephi-toolkit-tutorialtoolkit), 根据需求构造一个有向图,并调用布局算法, 最后导出成gexf和pdf文件


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

## 图表绘制

在得到数据文件后可以参考这个 **[Online Demo](https://nagland.github.io/201509/sigmajs/index.html)** 来绘制图表。


## 参考资料
1. http://gephi.github.io/
2. http://www.slideshare.net/gephi/gephi-toolkit-tutorialtoolkit
3. https://github.com/gephi/gephi/wiki/How-to-code-with-the-Toolkit

## Update:

1. 关于gexf文件的生成, 可以用这个python库: https://github.com/paulgirard/pygexf
2. 纯前端的话, sigma.js 提供了插件 https://github.com/jacomyal/sigma.js/tree/master/plugins/sigma.layout.forceAtlas2 来实现力导向算法

THE END
