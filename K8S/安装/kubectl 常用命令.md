## kubectl 常用命令

https://blog.fleeto.us/post/kubectl-in-5-min/
![](https://blog.fleeto.us/post/kubectl-in-5-min/images/kubectl-command.png)

#### 1.kubectl apply 

使用文件或标准输入应用或更新k8s资源

使用 example-service.yaml 中的定义创建服务。

kubectl apply -f example-service.yaml

使用 example-controller.yaml 中的定义创建 replication controller。

kubectl apply -f example-controller.yaml

使用 <directory> 路径下的任意 .yaml, .yml, 或 .json 文件 创建对象。

kubectl apply -f <directory>


####2.kubectl get 

列出一个或多个资源。

以纯文本输出格式列出所有 pod。

kubectl get pods

以纯文本输出格式列出所有 pod，并包含附加信息(如节点名)。

kubectl get pods -o wide

以纯文本输出格式列出具有指定名称的副本控制器。提示：你可以使用别名 'rc' 缩短和替换 'replicationcontroller' 资源类型。

kubectl get replicationcontroller <rc-name>

以纯文本输出格式列出所有副本控制器和服务。

kubectl get rc,services

以纯文本输出格式列出所有守护程序集。

kubectl get ds

列出在节点 server01 上运行的所有 pod
kubectl get pods --field-selector=spec.nodeName=server01


####3.kubectl describe

显示名称为 <node-name> 的节点的详细信息。
kubectl describe nodes <node-name>

显示名为 <pod-name> 的 pod 的详细信息。
kubectl describe pods/<pod-name>

显示由名为 <rc-name> 的副本控制器管理的所有 pod 的详细信息。
记住：副本控制器创建的任何 pod 都以复制控制器的名称为前缀。
kubectl describe pods <rc-name>

描述所有的 pod
kubectl describe pods


注意：
kubectl get 命令通常用于检索同一资源类型的一个或多个资源。 它具有丰富的参数，允许您使用 -o 或 --output 参数自定义输出格式。您可以指定 -w 或 --watch 参数以开始观察特定对象的更新。 kubectl describe 命令更侧重于描述指定资源的许多相关方面。它可以调用对 API 服务器 的多个 API 调用来为用户构建视图。 例如，该 kubectl describe node 命令不仅检索有关节点的信息，还检索在其上运行的 pod 的摘要，为节点生成的事件等。



####4.kubectl delete
从文件、标注输入或指定标签选择器、名称、资源选择器或资源中删除资源。
使用 pod.yaml 文件中指定的类型和名称删除 pod。
kubectl delete -f pod.yaml

删除标签名= <label-name> 的所有 pod 和服务。
kubectl delete pods,services -l name=<label-name>

删除所有具有标签名称= <label-name> 的 pod 和服务，包括未初始化的那些。
kubectl delete pods,services -l name=<label-name> --include-uninitialized

删除所有 pod，包括未初始化的 pod。
kubectl delete pods --all


####5.kubectl exec
对pod中的容器执行命令。
从 pod <pod-name> 中获取运行 'date' 的输出。默认情况下，输出来自第一个容器。
kubectl exec <pod-name> date
  
运行输出 'date' 获取在容器的 <container-name> 中 pod <pod-name> 的输出。
kubectl exec <pod-name> -c <container-name> date

获取一个交互 TTY 并运行 /bin/bash <pod-name >。默认情况下，输出来自第一个容器。
kubectl exec -ti <pod-name> -- /bin/bash


####6.kubectl logs
打印 Pod 中容器的日志。
从 pod 返回日志快照。
kubectl logs <pod-name>

从 pod <pod-name> 开始流式传输日志。这类似于 'tail -f' Linux 命令。
kubectl logs -f <pod-name>








 
