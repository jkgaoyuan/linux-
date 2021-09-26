### k8s API

本章内容了解即可

#### 什么是 k8s API

Kubernetes api 是系统声明配置架构 的基础， kubectl命令行工具用于创建， 变更、删除， 获取api对象。Kubernetes 通过api资源存储自己的序列化状态， （这些状态存储在 etcd 中）。 Kubernetes 被分为多个组件， 各个组件通过api相互交互/

#### api变更

新增api资源和资源字段不会导致向下兼容的问题， 删除一个已有的资源或资源字段， 必须通过 api废弃流程来进行。
 
#### openapi和 apiswagger 定义
k8s的 api 从 1.10开始 将原有的 swager 转换之 openapi
1.14中已被删除 swagger

kubectl 


#### API 版本

Alpha  
Beta
Stable


#### api组

为了更容易的扩展k8s api ，我们采用api组的方式。api组在rest路径和序列化对象的 api version字段中指定。 

1. 核心组 通常被称为遗留组 位于 rest 路径 /api/v1 并使用api version v1。
2. 指定的组位于 rest 路径/apis/$grroup_name/$version


