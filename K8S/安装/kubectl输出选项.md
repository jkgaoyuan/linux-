## kubectl输出选项

#### 1.格式输出 （常用）
kubectl可以通过-o选项已特定格式在终端端口输出详细信息
    
#### 语法
	
kubectl [command] [TYPE] [NAME] -o=<output_format>

#### 可支持的选项

[![4IdWkD.png](https://z3.ax1x.com/2021/09/30/4IdWkD.png)](https://imgtu.com/i/4IdWkD)

将单个pod详细信息输出为yaml格式
kubectl get pod web-pod-13je7 -o yaml


#### 2.自定义列（不常用）


使用custom-columns，可以自定义列并将所需的信息输出到表中。通常使用两种方法
-o=custom-columns=<spec> 或 -o=custom-columns-file=<filename>

* 内联
	
kubectl get pods pod-name -o custom-columns=NAME:.metadata.name,RSRC:.resourceVersion

`NAME    RSRC `

`nginx   <none>`


* 模版文件
创建template.txt 写入
NAME          RSRC
metadata.name metadata.resourceVersion

并通过如下命令执行
kubectl get pods pod-name -o custom-columns-file=template.txt 

#### 3.server-sids列
通过该命令可以打印任何指定资源的信息

kubectl get pods nginx --server-print=false

kubectl get pods pod-name --server-print=false


NAME    AGE

nginx   22h

#### 4.排序列表对象
通过--sort-by 指定任何数值或字符串对对象进行排序， 指定字段需要jsonpath表达式

kubectl [command] [TYPE] [NAME] --sort-by=<jsonpath_exp>

kubectl get pods -n kube-system --sort-by=.metadata.name









