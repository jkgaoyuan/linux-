### k8s的附加组件

附加组件 使用Kubernetes的资源， （如 daemonset delpyment。 statefulset等 ）实现集群功能， 英文他们提供的是集群级别的属性， 故需要部署在** kube-system**这个命名空间中。

相关组件如下： 

1. coredns
	
	k8s 1.11 之前使用的kube-dns， croedns为 Kubernetes services 提供dns服务
2. web ui (dashboard)
	
	Dashboard是k8s的集群的web ui管理页面， 可实现对相关资源的操作， 如 pod的创建， 创建存储，创建网络， 也可以监控pod和节点资源使用情况。  	
3. ingress contorller
	
	七层负载均衡控制器， 通过创建nginx或者traefik这种七层负载组件实现域名或者https的访问。  
4. prometheus+alertmanager+grafana
	
	监控系统， 可以对Kubernetes 集群本身的组件监控，也可以对物理节点，容器做监控， 对监控到的超过报警阀值的数据进行报警， 这个报警会发送到指定的目标，如微信 钉钉 等。 	
5. efk -- elasticsearch\ fluentd\ kibana
	
	日志管理系统， 可以对物理节点和容器的日志进行统一的收集， 将收集到的数据在kibana界面展示， kibana提供按照指定条件过滤和搜索日志。 	
6. metrics
	
	用于收集资源指标，hpa需要基于metrics实现自动扩缩容。 
	



