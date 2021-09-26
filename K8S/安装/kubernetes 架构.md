### kubernetes 架构
k8s的物理结构是 master/node 模式 如下
[![fzbnv6.png](https://z3.ax1x.com/2021/08/22/fzbnv6.png)](https://imgtu.com/i/fzbnv6)

**上图中只说明了 一部分的 master 和node 节点**， 可补充完整。 
	
master 一般是三个节点或者五个节点做高可用， 通常master 节点的数量是根据集群的规模来决定的 ， master高可用之的是对 apiserver 做高可用， 或对master的物理节点做高可用。 


node可有多个节点， 专门用来部署应用。 	
