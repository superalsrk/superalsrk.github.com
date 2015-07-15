---
title: 读取文件的正确方式
date: 2015-06-19 01:48:34
tags: ['基础','Java']
description: "IO好复杂系列"
keywords: "HDFS,BufferStream,hdfs文件截断"
toc: true
---


# 缘由

最近在写一个MapReduce程序的时候,出现了读取HDFS文件截断的情况,代码如下:

```
//fs : FileSystem
InputStream in = null;
byte[] b = new byte[1024 * 1024 * 64];
int len = 0;
try {
	in = fs.open(new Path(fileName));
	len = in.read(b);
    } catch (Exception e) {
    	e.printStackTrace();
    } finally {
    	try {
    		in.close();
    	} catch (IOException e) {
    		e.printStackTrace();
    	}
    }
return new String(b, 0, len);
```

理论上,bytes数组大小已经设置为了64MB, 远远大于要读取的文件,那为什么会出现这种情况呢？
一开始怀疑 `InputStream.read()` 方法导致截断,果然,改成用BufferedReader读取的方式就好用了。

```
BufferedReader reader = null;
StringBuilder sb = new StringBuilder();
try {
    reader = new BufferedReader(new InputStreamReader(fs.open(new Path(fileName))));
    String line = null;

    while((line = reader.readLine()) != null) {
        sb.append(line);
    }
    } catch (Exception ioe) {
        System.out.println(fileName + " does't exist!");
    } finally {
        try {
            reader.close();
        } catch (IOException e) {
            System.out.println("Reader close failed");
        }
    }
    return sb.toString();
}
```

但真实的原因真的是这样么？
# 分析

由上段代码可知, `InputStream.read()`读取的byte长度和期望值不同,我在 [API  Docs](http://docs.oracle.com/javase/7/docs/api/java/io/InputStream.html)中发现了这么一个定义
> An attempt is made to read as many as len bytes, but a smaller number may be read.

也就是说, `read()` 方法只是尽量的去读stream,不保证读取stream中全部的字节。类似的还有 `availabe()`方法,这个方法同样不保证返回正确的stream大小,而导致这些状况的原因可能有以下几点:
1. 硬件上的buffersize比较小
2. 网络的IO比较慢
3. 文件是分布式的,组合在一起时需要花费一些时间

最后关于解决方法,除了使用Reader一行一行读以外, 使用 `DataInputStream.readFully()` 也能避免这种问题。

THE END
