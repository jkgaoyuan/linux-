### k8s master 节点


master节点可以在集群中任意的机器中运行，为了简单通常只会在一台机器中运行master节点组件，且运行 master 组件的机器最好不要运行其他的容器化程序。 


#### master 组件
 
1. kube-apiserver  
	
	kube-apiserver 是kubernetes master节点组件， 其公开了 Kubernetes API。 
	
	api服务是 Kubernetes  master的前端，Kubernetes api 服务是通过， kube-apisserver 组件实现的， 
	kube-apiserver 时可自行进行扩缩绒， 你可以运行多个 kube -apiserver组件，通过 keeplive+lvs 或其他负载均衡，平衡这些流量。 
	
	kube-apiserver提供了 资源操作的唯一入口， 并提供认证， 授权 访问控制， api 注册和发现等机制，扶着接受、解析、处理、请求。 	
 
2. kube-scheduler
		 
	kube- scheduler 是Kubernetes master 节点组件， 用来监视已被创建单没有调度到node节点的 pod， 
	然后选择一个node节点来运行它， kube-scheduler 主要负责pod的调度，按照预定策略，(亲和性、反亲和性)将pod 调度到相应的机器上。  

			 	
3. kuber- controller- manager 
	
	控制器管理器，用于检测控制器健康状态， 控制器是维护pod集群的状态， 检测pod的健康状态， 如 故障检测、自动扩展、滚动更新等操作。  
	滚动更新： 灰度发布， 金丝雀发布
	
	补充： 什么是**控制器**？  
	
	pod 作为k8s的最小单元， 用于管理pod的状态和行为就称为控制器。 
	
	有如下5种控制器
	

	* 		deployment
	* 	    statefullset
	* 	 	daemonset
	* 	  	job
	* 	  	cronjob


	
4. etcd
	
	etcd 是一种 key/value形式的键值存储， 保存了Kubernetes 集群的状态， 使用 etcd 时需要对etcd做备份， 实现高可用。 
	整个k8s中有两个服务需要 etcd 协同和存储配置： 

	1. 网络插件 calio、对于其他网络插件也是需要 用到etcd。作为存储网络的配置信息 
	
	
	2. k8s本身，包括各种对象的状态和元信息的配置。
	 
	 注意： 网络插件操作etcd 使用的是 v2 版本的 api，而 k8s 操作 etcd时使用的是v3版本的 api。
	 所以我们在执行etcdctl的时候需要设置ETCDCTL_API，环境变量， 默认为2， 表示使用 v2 版本的 API， v3同理
	 
	 	
	 	
5. docker

	容器引擎， 用于运行容器。
	 
6. kube proxy
	
	k8s代理， 是集群中每个节点上运行的网络代理，kube proxy 负责请求的转发， 一旦发现某个 service关联的额pod信息发生了改变（IP port等），由kube-proxy 将变化后的service 转换成ipvs或者iptables规则， 完成对后端pod的负载均衡。 
7. calico

	calico 是一个 纯三层的网络插件， calico的 bgp 模式， 类似于 host-gw， calico在kubernetes中可提供网络功能和网络策略。 
	
8. crodns
	
	k8s1.11之前使用的是kube dns 1.11 之后才有 coredns。 coredns 是一个dns服务器，为k8s services提供 dns 服务。 
9. kubelet
	
	负责与master节点的 apiserver进行通讯， 接收到客户端请求后，创建 pod ， 管理 pod，启动pod 等相关操作。 	 
	
	
    
    	 
    	 


	
 