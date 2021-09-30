# 命令行工具-kubectl
### 简介
kubectl 是操作k8s集群的命令行工具。部署在master 节点 kubectl在$HOME/.kube目录中查找一个config文件， 可以通过kubeconfig 环境变量或使用--kubeconfig 指定其他的kubeconfig 文件


### 语法格式

kubectl command type name flags


command 指定要一个或多个对象 

	eg create get describe delete 
	
type 指定资源类型 不区分大小写 可以指定单数 复数缩写 

	eg  kubectl get pods pod1
		kubectl get pod pod1
		kubectl get po pod1
		
这些命令输出的结果都是相同的。 


name 指定资源名称 区分大小写 如省略吗，默认将输出所有的资源详情


	kubectl get pods


flags 指定可选参数  可以使用 -s or -server 指定Kubernetes api 服务器地址或者端口。 


		
在命令行指定的参数将会默认覆盖默认值和任何相应的环境变量





1. 按照类型或名称指定资源	
	
	对所有类型相同的资源进行分组
	kubectl get pod example-pod1 example-pod2
	分别制定多个资源类型
	kubectl get pod/example-pod1 deployment/example-dep1
2. kubectl --help 

	帮助命令
	
3. 用一个或多个文件指定资源
	kubectl get pod -f pod.yaml 


### 实例操作


1. annotate

1）语法：
kubectl annotate (-f FILENAME | TYPE NAME | TYPE/NAME) KEY_1=VAL_1 … KEY_N=VAL_N [--overwrite] [--all] [--resource-version=version] [flags]

2）描述：
添加或更新一个或多个资源的注释。

**2. api-versions**

1）语法：
kubectl api-versions [flags]
2）描述：
列出可用的api版本

**3.apply**

1）语法：
kubectl apply -f FILENAME [flags]
从文件或stdin对资源的应用配置进行更改。



4.attach-不用

1）语法：
kubectl attach POD-name -c CONTAINER-name  [-i] [-t] [flags]
附加到正在运行的容器，查看输出流或与容器交互。

**5.autoscale**

1）语法：
kubectl autoscale (-f FILENAME | TYPE NAME | TYPE/NAME) [--min=MINPODS] --max=MAXPODS [--cpu-percent=CPU] [flags]
自动扩缩容由副本控制器管理的一组 pod。

6.cluster-info

1）语法：
kubectl cluster-info [flags]
显示有关集群中的主服务器和服务的端点信息。

7.config

1）语法：
kubectl config SUBCOMMAND [flags]
修改kubeconfig文件
 
8.create-一般不用，用apply替代这个

1）语法：
kubectl create -f FILENAME [flags]
从文件或标准输入创建一个或多个资源。

**9.delete**

1）语法：
kubectl delete (-f FILENAME | TYPE [NAME | /NAME | -l label | --all]) [flags]
从文件、标准输入或指定标签选择器、名称、资源选择器或资源中删除资源。

**10.describe**

1）语法：
kubectl describe (-f FILENAME | TYPE [NAME_PREFIX | /NAME | -l label]) [flags]
显示一个或多个资源的详细状态。

 kubectl describe pods nginx 

11.diff

1）语法：
kubectl diff -f FILENAME [flags]
将 live 配置和文件或标准输入做对比 (BETA版)

**12.edit**

1）语法：
kubectl edit (-f FILENAME | TYPE NAME | TYPE/NAME) [flags]
使用默认编辑器编辑和更新服务器上一个或多个资源的定义。

**13.exec-常用的**

1）语法：
kubectl exec POD-name [-c CONTAINER-name] [-i] [-t] [flags] [-- COMMAND [args...]]
对 pod 中的容器执行命令。

下面的命令就是登录到pod中的容器的命令
kubectl exec calico-node-cblk2 -n kube-system -i -t -- /bin/sh


**14.explain-常用的**

1）语法：
kubectl explain [--recursive=false] [flags]
获取多种资源的文档。例如 pod, node, service 等，相当于帮助命令，可以告诉我们怎么创建资源

**15.expose**

1）语法：
kubectl expose (-f FILENAME | TYPE NAME | TYPE/NAME) [--port=port] [--protocol=TCP|UDP] [--target-port=number-or-name] [--name=name] [--external-ip=external-ip-of-service] [--type=type] [flags]
将副本控制器、服务或pod作为新的Kubernetes服务进行暴露。

**16.get**

1）语法：
kubectl get (-f FILENAME | TYPE [NAME | /NAME | -l label]) [--watch] [--sort-by=FIELD] [[-o | --output]=OUTPUT_FORMAT] [flags]
列出一个或多个资源。

17.label

1）语法：
kubectl label (-f FILENAME | TYPE NAME | TYPE/NAME) KEY_1=VAL_1 … KEY_N=VAL_N [--overwrite] [--all] [--resource-version=version] [flags]
添加或更新一个或多个资源的标签。

**18.logs**

1）语法：
kubectl logs POD [-c CONTAINER] [--follow] [flags]
在 pod 中打印容器的日志。

19.patch

1）语法：
kubectl patch (-f FILENAME | TYPE NAME | TYPE/NAME) --patch PATCH [flags]
更新资源的一个或多个字段

20.port-forward

1）语法：
kubectl port-forward POD [LOCAL_PORT:]REMOTE_PORT [...[LOCAL_PORT_N:]REMOTE_PORT_N] [flags]
将一个或多个本地端口转发到Pod。

21.proxy

1）语法：
kubectl proxy [--port=PORT] [--www=static-dir] [--www-prefix=prefix] [--api-prefix=prefix] [flags]
运行Kubernetes API服务器的代理。

22.replace

1）语法：
kubectl replace -f FILENAM
从文件或标准输入中替换资源。

**23.run**

1）语法：
kubectl run NAME --image=image [--env=“key=value”] [--port=port] [--dry-run=server | client | none] [--overrides=inline-json] [flags]
在集群上运行指定的镜像

24.scale

1）语法：
kubectl scale (-f FILENAME | TYPE NAME | TYPE/NAME) --replicas=COUNT [--resource-version=version] [--current-replicas=count] [flags]
更新指定副本控制器的大小。
25.version

1）语法：
kubectl version [--client] [flags] 
显示运行在客户端和服务器上的 Kubernetes 版本







	
	

	
	