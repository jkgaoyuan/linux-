# 二进制安装多master节点

相关参考文件 二进制安装多master节点的k8s集群-1.20+稳定版本

二进制和kubeadm 安装的不同。 

kubeadm是一个开源工具， 可快速构建k8s， kubeadm init 会自动安装k8s。 属于自动化部署， 自动化部署不会展示很多细节，不便于排查。 

kubeadm 初始化k8s，所有的组件都是一pod运行的， 具有故障自回复能力。 也更适合批量或者自动化高的场景。 

Pod网段：   10.0.0.0/16

Service网段：  10.255.0.0/16

#### 部署master 和  node 节点 的准备工作



​	将master和 node 节点机器上的 selinux swap  关闭  





​	在master 和  node 节点上备份默认的 repos， 并将其替换为阿里云的 repo

 for i in {master2,master3};do scp  /etc/yum.repos.d/CentOS-Base.repo root@$i:/etc/yum.repos.d/;done

ansible master2,master3,node -m command -a 'mkdir /root/repo.back'

配置阿里云的docker软件加速源

ansible master,node -m shell -a 'yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo'



如机器中没有部署ipvs的话k8s默认是通过iptables进行数据转发



ansible node,master -m shell -a ' chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep ip_vs'



安装docker 配置开机启动

 ansible master,node -m shell -a 'yum install docker-ce docker-ce-cli containerd.io -y '

ansible master,node -m shell -a 'systemctl start docker && systemctl enable docker.service && systemctl status docker '



#### 配置docker 镜像加速



 tee /etc/docker/daemon.json << 'EOF'

{

 "registry-mirrors":["https://rsbud4vc.mirror.aliyuncs.com","https://registry.docker-cn.com","https://docker.mirrors.ustc.edu.cn","https://dockerhub.azk8s.cn","http://hub-mirror.c.163.com","http://qtid6917.mirror.aliyuncs.com", "https://rncxm540.mirror.aliyuncs.com"],

 "exec-opts": ["native.cgroupdriver=systemd"]

} 

EOF



分发 docker 加速的配置文件

ansible node,master3,master2 -m copy -a 'src=/etc/docker/daemon.json dest=/etc/docker/daemon.json'



重启加载新配置文件

ansible master,node -m shell -a 'systemctl daemon-reload && systemctl restart docker && systemctl status docker'







初始化完成 



#### 构建etcd

已经完成 etcd  ca证书的创建

已将etcd 文件同步到 maser 节点组



创建 etcd.conf  & etcd.service

并将etcd.service 同步到 /usr/lib/systemd/system 

etcd.conf同步到/etc/etcd/



ansible master2,master3 -m copy -a 'src=/etc/etcd/ dest=/etc/etcd/'



ansible master2,master3 -m copy -a 'src=/data/work/etcd.service dest=/usr/lib/systemd/system/etcd.service'



##### vim etcd.conf 

\#[Member]

ETCD_NAME="etcd1"

ETCD_DATA_DIR="/var/lib/etcd/default.etcd"

ETCD_LISTEN_PEER_URLS="https://192.168.120.180:2380"

ETCD_LISTEN_CLIENT_URLS="https://192.168.120.180:2379,http://127.0.0.1:2379"

\#[Clustering]

ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.12.180:2380"

ETCD_ADVERTISE_CLIENT_URLS="https://192.168.120.180:2379"

ETCD_INITIAL_CLUSTER="etcd1=https://192.168.120.180:2380,etcd2=https://192.168.120.181:2380,etcd3=https://192.168.120.182:2380"

ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"

ETCD_INITIAL_CLUSTER_STATE="new"

 

\#注：

ETCD_NAME：节点名称，集群中唯一 

ETCD_DATA_DIR：数据目录 

ETCD_LISTEN_PEER_URLS：集群通信监听地址 

ETCD_LISTEN_CLIENT_URLS：客户端访问监听地址 

ETCD_INITIAL_ADVERTISE_PEER_URLS：集群通告地址 

ETCD_ADVERTISE_CLIENT_URLS：客户端通告地址 

ETCD_INITIAL_CLUSTER：集群节点地址

ETCD_INITIAL_CLUSTER_TOKEN：集群Token

 ETCD_INITIAL_CLUSTER_STATE：加入集群的当前状态，new是新集群，existing表示加入已有集群

 



##### vim etcd.service 

[Unit]

Description=Etcd Server

After=network.target

After=network-online.target

Wants=network-online.target

 

[Service]

Type=notify

EnvironmentFile=-/etc/etcd/etcd.conf

WorkingDirectory=/var/lib/etcd/

ExecStart=/usr/local/bin/etcd \

 --cert-file=/etc/etcd/ssl/etcd.pem \

 --key-file=/etc/etcd/ssl/etcd-key.pem \

 --trusted-ca-file=/etc/etcd/ssl/ca.pem \

 --peer-cert-file=/etc/etcd/ssl/etcd.pem \

 --peer-key-file=/etc/etcd/ssl/etcd-key.pem \

 --peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \

 --peer-client-cert-auth \

 --client-cert-auth

Restart=on-failure

RestartSec=5

LimitNOFILE=65536

 

[Install]

WantedBy=multi-user.target





##### 创建 etcd 运行位置

ansible master -m shell -a 'mkdir -p /var/lib/etcd/default.etcd'

##### 将etcd.service 同步到 master节点后 重载  service 服务

ansible master -m shell -a 'systemctl daemon-reload'

ansible master -m shell -a 'systemctl enable etcd.service'

##### 启动etcd

ansible master -m shell -a 'systemctl start etcd.service'

##### 检查一下 etcd 节点是否完成启动

ansible master -m shell -a 'systemctl status etcd.service |grep running'
master1 | CHANGED | rc=0 >>
   Active: active (running) since Sun 2021-09-05 23:27:20 EDT; 29s ago
master3 | CHANGED | rc=0 >>
   Active: active (running) since Sun 2021-09-05 23:27:20 EDT; 29s ago
master2 | CHANGED | rc=0 >>
   Active: active (running) since Sun 2021-09-05 23:27:20 EDT; 29s ago



##### 检查 etcd 节点 状态是否出现异常



ETCDCTL_API=3

/usr/local/bin/etcdctl --write-out=table --cacert=/etc/etcd/ssl/ca.pem --cert=/etc/etcd/ssl/etcd.pem --key=/etc/etcd/ssl/etcd-key.pem --endpoints=https://192.168.120.180:2379,https://192.168.120.181:2379,https://192.168.120.182:2379  endpoint health 
+------------------------------+--------+-------------+-------+

| ENDPOINT                                                     | HEALTH | TOOK        | ERROR |
| ------------------------------------------------------------ | ------ | ----------- | ----- |
|                                                              |        |             |       |
| +------------------------------+--------+-------------+-------+ |        |             |       |
| https://192.168.120.181:2379                                 | true   | 63.0649ms   |       |
| ----------------------------                                 | ----   | ---------   | ----  |
|                                                              |        |             |       |
| https://192.168.120.180:2379                                 | true   | 66.943274ms |       |
| ----------------------------                                 | ----   | ----------- | ----  |
|                                                              |        |             |       |
| https://192.168.120.182:2379                                 | true   | 68.650834ms |       |
| ----------------------------                                 | ----   | ----------- | ----  |
|                                                              |        |             |       |
| +------------------------------+--------+-------------+-------+ |        |             |       |



#### 安装kubernets 组件 

##### 下载部署安装包

###### 同步master组件

下载的是 server bind  https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.20.md

下载 k8s server 文件 解压后 将

kube-controller-manager

kube-apiserver

kube-scheduler 

kubectl

同步到**master节点**下的   /usr/local/bin/ 中

ansible master -m shell -a 'ls /usr/local/bin/kube*' 

master3 | CHANGED | rc=0 >>
/usr/local/bin/kube-apiserver
/usr/local/bin/kube-controller-manager
/usr/local/bin/kubectl
/usr/local/bin/kube-scheduler
master2 | CHANGED | rc=0 >>
/usr/local/bin/kube-apiserver
/usr/local/bin/kube-controller-manager
/usr/local/bin/kubectl
/usr/local/bin/kube-scheduler
master1 | CHANGED | rc=0 >>
/usr/local/bin/kube-apiserver
/usr/local/bin/kube-controller-manager
/usr/local/bin/kubectl
/usr/local/bin/kube-scheduler



###### 同步 node 节点组件 

rsync -avz kubectl kubelet kube-proxy node1:/usr/local/bin/



创建k8s log 和配置文件路径

在master1 上执行  这里看 并未在 master2 3 中创建 这两个路径 

mkdir -p /etc/kubernetes/ssl

 mkdir /var/log/kubernetes

##### 启用tsl bootstrap  部署apiserver

tsl bootstrap 功能就是让kubelet 去apiserver 申请证书， 用于连接apiserver

1. tls的作用

   1. kuberlet与apiserver 通信的过程 是需要通过 tls 进行加密的，  如node 节点众多 需要客户端不断进行证书签发。没有通过ca证书进行验证的话是没权限想apiserver请求任何信息。
   2. bootstraping 就是为了解决该问题而引入。

2. rbac的作用

   1.  rbac 即基于用户角色的权限控制
   2.  其定义了一个用户或者用户组具有请求api的权限， 配合 TLS 加密的时候，实际上 apiserver 读取客户端证书的 CN 字段作为用户名，读取 O字段作为用户组.

3. kubelet 首次启动流程

   1. 首次启动apiserver 时并没有相关的证书，是通过apiserver配置中指定了一个 token.csv  文件来对用户进行鉴权的。  该文件包含用户token和被apiserver信任的用户。

   2. token.csv里的token和 被apiserver  ca 证书颁发机构 信任的用户 kubelet-bootstrap ， 被写在 bootstrap.kubeconfig 文件中。 kubelete 启动会加载 bootstrap.kubeconfig 文件， 

      1. token.csv格式:

         3940fd7fbb391d1b4d861ad17a1f0613,**kubelet-bootstrap,**10001,"system:kubelet-bootstrap"

         格式：token，用户名，UID，用户组

         cat > token.csv << EOF

         $(head -c 16 /dev/urandom | od -An -t x | tr -d ' '),kubelet-bootstrap,10001,"system:kubelet-bootstrap"

         EOF

   3. kubelet第一次启动时， kubelet 会使用 boostrap.kubeconfig 文件中的用户 kubelet-boostrap 和 apiserver 建立 tls通信

   4. 使用bootstrap.kubeconfig 文件中的 token apiserver 声明自己的授权。  

   5. 首次启动时 可能会出现 kubelet  error 401 无权访问apiserver的错误。 这是由于在默认的情况下。 kubelet 通过bootstrap.kubeconfig中预设用户token声明了自己的身份，然后创建 CSR 请求； 但是默认情况下我们如果不做处理， 该用户时没有权限的。 

   6. 故我们需要创建 **clusterrolebinding**， 将用户 kubelet-bootstrap用户与内置的 clusterrole system:node-bootstrapper 绑定到一起，使其能有**权限**够发起 CSR 请求。

实际操作如下： 

###### 	创建toke csv文件:

​		`cat > token.csv << EOF``$(head -c 16 /dev/urandom | od -An -t x | tr -d ' '),kubelet-bootstrap,10001,"system:kubelet-bootstrap"``EOF`

######  	创建apiserver的 csr 生成证书配置文件

`{`
 `"CN": "kubernetes",`
 `"hosts": [`
  `"127.0.0.1",`
  `"192.168.120.180",`
  `"192.168.120.181",`
  `"192.168.120.182",`
  `"192.168.120.183",`
  `"192.168.120.199",`
  `"10.255.0.1",`
  `"kubernetes",`
  `"kubernetes.default",`
  `"kubernetes.default.svc",`
  `"kubernetes.default.svc.cluster",`
  `"kubernetes.default.svc.cluster.local"`
 `],`
 `"key": {`
  `"algo": "rsa",`
  `"size": 2048`
 `},`
 `"names": [`
  `{`
   `"C": "CN",`
   `"ST": "Hubei",`
      `"L": "Wuhan",`
   `"O": "k8s",`
   `"OU": "system"`
  `}`
 `]`
`}`



###### 创建apiserver的配置文件

​		kube-apiserver.conf 

	`KUBE_APISERVER_OPTS="--enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
	  --anonymous-auth=false \
	  --bind-address=192.168.120.180 \
	  --secure-port=6443 \
	  --advertise-address=192.168.120.180 \
	  --insecure-port=0 \
	  --authorization-mode=Node,RBAC \
	  --runtime-config=api/all=true \
	  --enable-bootstrap-token-auth \
	  --service-cluster-ip-range=10.255.0.0/16 \
	  --token-auth-file=/etc/kubernetes/token.csv \
	  --service-node-port-range=30000-50000 \
	  --tls-cert-file=/etc/kubernetes/ssl/kube-apiserver.pem  \
	  --tls-private-key-file=/etc/kubernetes/ssl/kube-apiserver-key.pem \
	  --client-ca-file=/etc/kubernetes/ssl/ca.pem \
	  --kubelet-client-certificate=/etc/kubernetes/ssl/kube-apiserver.pem \
	  --kubelet-client-key=/etc/kubernetes/ssl/kube-apiserver-key.pem \
	  --service-account-key-file=/etc/kubernetes/ssl/ca-key.pem \
	  --service-account-signing-key-file=/etc/kubernetes/ssl/ca-key.pem  \
	  --service-account-issuer=https://kubernetes.default.svc.cluster.local \
	  --etcd-cafile=/etc/etcd/ssl/ca.pem \
	  --etcd-certfile=/etc/etcd/ssl/etcd.pem \
	  --etcd-keyfile=/etc/etcd/ssl/etcd-key.pem \
	  --etcd-servers=https://192.168.120.180:2379,https://192.168.120.181:2379,https://192.168.120.182:2379 \
	  --enable-swagger-ui=true \
	  --allow-privileged=true \
	  --apiserver-count=3 \
	  --audit-log-maxage=30 \
	  --audit-log-maxbackup=3 \
	  --audit-log-maxsize=100 \
	  --audit-log-path=/var/log/kube-apiserver-audit.log \
	  --event-ttl=1h \
	  --alsologtostderr=true \
	  --logtostderr=false \
	  --log-dir=/var/log/kubernetes \
	  --v=4"`


###### 创建apiserver的管理服务

kube-apiserver.service

`[Unit]`
`Description=Kubernetes API Server`
`Documentation=https://github.com/kubernetes/kubernetes`
`After=etcd.service`
`Wants=etcd.service`

`[Service]`
`EnvironmentFile=-/etc/kubernetes/kube-apiserver.conf`
`ExecStart=/usr/local/bin/kube-apiserver $KUBE_APISERVER_OPTS`
`Restart=on-failure`
`RestartSec=5`
`Type=notify`
`LimitNOFILE=65536`

`[Install]`
`WantedBy=multi-user.target`

###### 配置kube-apiserver 服务

   将相关文件同步到 所有的 master 节点上并启动服务

​	cp ca*.pem /etc/kubernetes/ssl

​	cp kube-apiserver*.pem /etc/kubernetes/ssl/

​	cp token.csv /etc/kubernetes/

​	cp kube-apiserver.conf /etc/kubernetes/

​	cp kube-apiserver.service /usr/lib/systemd/system/

​	 rsync -vaz token.csv master2:/etc/kubernetes/

​	 rsync -vaz token.csv master3:/etc/kubernetes/

​	rsync -vaz kube-apiserver*.pem master2:/etc/kubernetes/ssl/

​	rsync -vaz kube-apiserver*.pem master3:/etc/kubernetes/ssl/

 rsync -vaz ca*.pem master2:/etc/kubernetes/ssl/

 rsync -vaz ca*.pem master3:/etc/kubernetes/ssl/

rsync -vaz kube-apiserver.conf  master2:/etc/kubernetes/

rsync -vaz kube-apiserver.conf  master3:/etc/kubernetes/

rsync -vaz kube-apiserver.service  master2:/usr/lib/systemd/system/

rsync -vaz kube-apiserver.service  master3:/usr/lib/systemd/system/

同步完成后修改 master2 master3 中  bind-address 和advertise-address 参数至 本机ip   即 修改监听地址和集群通告地址

ansible master -m shell -a 'systemctl daemon-reload'

​	ansible master -m shell -a 'systemctl enable kube-apiserver.service'

​	ansible master -m shell -a 'systemctl restart kube-apiserver.service'

​	ansible master -m shell -a 'systemctl status kube-apiserver.service |grep running'

##### 部署kubectl 组件

   常见命令

​	 kubectl getpod 

​	kubectl deletepod

​	kubectl apply -f

​	kubectl set 

​	kubectl replace

​	kubectl edit

kubectl 作为一个客户端工具管理时时需要基于  这个配置文件kubernetes/admin.conf



同时kubectl 要和 apiserver 通信， 我们依然需要创建由apiserver 签发的 证书用于通信 

###### 创建csr文件

vim admin-csr.json 

{

 "CN": "admin",

 "hosts": [],

 "key": {

  "algo": "rsa",

  "size": 2048

 },

 "names": [

  {

   "C": "CN",

   "ST": "Hubei",

   "L": "Wuhan",

   "O": "system:masters",       

   "OU": "system"

  }

 ]

} 

###### 生成证书

`cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin`

将admin-key.pem  admin.pem 同步到/etc/kubernetes/ssl/

###### 创建安全上下文

 创建kubeconfig ，其为kubectl 的配置问渐渐包含访问napiserve的所有信息， 如 apiserver的地址  ca证书和自生使用的证书

1. 配置集群参数

   1. kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://192.168.120.180:6443 --kubeconfig=kube.config

2. 配置客户端参数

   1. kubectl config set-credentials admin --client-certificate=admin.pem --client-key=admin-key.pem --embed-certs=true --kubeconfig=kube.config

      ​			

3. 设置上下文参数

   1. kubectl config set-context kubernetes --cluster=kubernetes --user=admin --kubeconfig=kube.config

4. 设置当前上下文

   1. kubectl config use-context kubernetes --kubeconfig=kube.config
   2. mkdir ~/.kube -p
   3. cp kube.config ~/.kube/config

5. 授权kubernetes 证书访问kubelet api权限  （不授权的话 是没有 create apply 等权限的）

   1. kubectl create clusterrolebinding kube-apiserver:kubelet-apis --clusterrole=system:kubelet-api-admin --user kubernetes

6. /root/.kube/ 下的文件同步到 master2 3 上

   1. ansible master2,master3 -m copy -a 'src=/root/.kube/ dest=/root/.kube/'



###### 配置kubectl 命令补全

在所有的 master节点执行

`yum install -y bash-completion`

`source /usr/share/bash-completion/bash_completion`

`source <(kubectl completion bash)`

 `kubectl completion bash > ~/.kube/completion.bash.inc`

`source '/root/.kube/completion.bash.inc'`

 `source $HOME/.bash_profile`



 Kubectl官方备忘单：  命令 详解

https://kubernetes.io/zh/docs/reference/kubectl/cheatsheet/



##### 部署controller-manager

###### 创建csr文件

vim  kube-controller-manager-csr.json

`{
    "CN": "system:kube-controller-manager",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [
      "127.0.0.1",
      "192.168.120.180",
      "192.168.120.181",
      "192.168.120.182",
      "192.168.120.199"
    ],
    "names": [
      {
        "C": "CN",
        "ST": "Hubei",
        "L": "Wuhan",
        "O": "system:kube-controller-manager",
        "OU": "system"
      }
    ]
}`

###### 生成证书

`cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager`



###### 创建 kube-controller-manager的kube config

1. 设置集群参数
   1. kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://192.168.40.180:6443 --kubeconfig=kube-controller-manager.kubeconfig
2. 设置客户端认证参数
   1. kubectl config set-credentials system:kube-controller-manager --client-certificate=kube-controller-manager.pem --client-key=kube-controller-manager-key.pem --embed-certs=true --kubeconfig=kube-controller-manager.kubeconfig
3. 设置上下文参数
   1. kubectl config set-context system:kube-controller-manager --cluster=kubernetes --user=system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig
4. 设置当前上下文
   1. kubectl config use-context system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig



###### 创建kube-controller-manager.conf 

`vim kube-controller-manager.service`

`KUBE_CONTROLLER_MANAGER_OPTS="--port=0 \`

 `--secure-port=10252 \`

 `--bind-address=127.0.0.1 \`

 `--kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \`

 `--service-cluster-ip-range=10.255.0.0/16 \`

 `--cluster-name=kubernetes \`

 `--cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem \`

 `--cluster-signing-key-file=/etc/kubernetes/ssl/ca-key.pem \`

 `--allocate-node-cidrs=true \`

 `--cluster-cidr=10.0.0.0/16 \`

 `--experimental-cluster-signing-duration=87600h \`

 `--root-ca-file=/etc/kubernetes/ssl/ca.pem \`

 `--service-account-private-key-file=/etc/kubernetes/ssl/ca-key.pem \`

 `--leader-elect=true \`

 `--feature-gates=RotateKubeletServerCertificate=true \`

 `--controllers=*,bootstrapsigner,tokencleaner \`

 `--horizontal-pod-autoscaler-use-rest-clients=true \`

 `--horizontal-pod-autoscaler-sync-period=10s \`

 `--tls-cert-file=/etc/kubernetes/ssl/kube-controller-manager.pem \`

 `--tls-private-key-file=/etc/kubernetes/ssl/kube-controller-manager-key.pem \`

 `--use-service-account-credentials=true \`

 `--alsologtostderr=true \`

 `--logtostderr=false \`

 `--log-dir=/var/log/kubernetes \`

 `--v=2"`

###### 创建 kube-controller-manager 启动服务

vim kube-controller-manager.service

`[Unit]`

`Description=Kubernetes Controller Manager`

`Documentation=https://github.com/kubernetes/kubernetes`

`[Service]`

`EnvironmentFile=-/etc/kubernetes/kube-controller-manager.conf`

`ExecStart=/usr/local/bin/kube-controller-manager $KUBE_CONTROLLER_MANAGER_OPTS`

`Restart=on-failure`

`RestartSec=5`

`[Install]`

`WantedBy=multi-user.target`



###### 同步配置文件 证书 服务

kube-controller-manager.service

ansible master -m copy -a 'src=/data/work/kube-controller-manager.service dest=/usr/lib/systemd/system/kube-controller-manager.service'

kube-controller-manager.conf

ansible master -m copy -a 'src=/data/work/kube-controller-manager.conf dest=/etc/kubernetes/kube-controller-manager.conf'

kube-controller-manager.kubeconfig

ansible master -m copy -a 'src=/data/work/kube-controller-manager.kubeconfig dest=/etc/kubernetes/kube-controller-manager.kubeconfig'

kube-controller-manager-key.pem

ansible master -m copy -a 'src=/data/work/kube-controller-manager-key.pem dest=/etc/kubernetes/ssl/kube-controller-manager-key.pem'

kube-controller-manager.pem

ansible master -m copy -a 'src=/data/work/kube-controller-manager.pem dest=/etc/kubernetes/ssl/kube-controller-manager.pem'

###### 重载服务并启动 controller-manager

ansible master -m shell -a 'systemctl daemon-reload'

ansible master -m shell -a 'systemctl enable kube-controller-manager.service'

ansible master -m shell -a 'systemctl start kube-controller-manager.service'



##### 部署kube-scheduler

###### 创建csr文件

vim kube-scheduler-csr.json 

{

  "CN": "system:kube-scheduler",

  "hosts": [

   "127.0.0.1",

   "192.168.40.180",

   "192.168.40.181",

   "192.168.40.182",

   "192.168.40.199"

  ],

  "key": {

​    "algo": "rsa",

​    "size": 2048

  },

  "names": [

   {

​    "C": "CN",

​    "ST": "Hubei",

​    "L": "Wuhan",

​    "O": "system:kube-scheduler",

​    "OU": "system"

   }

  ]

}

###### 生成证书

`cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler`

###### 创建kube-scheduler的kubeconfig

1. 设置集群参数
   1. kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://192.168.120.180:6443 --kubeconfig=kube-scheduler.kubeconfig
2. 设置客户端请求参数
   1. kubectl config set-credentials system:kube-scheduler --client-certificate=kube-scheduler.pem --client-key=kube-scheduler-key.pem --embed-certs=true --kubeconfig=kube-scheduler.kubeconfig 
3. 设置上下文参数
   1. kubectl config set-context system:kube-scheduler --cluster=kubernetes --user=system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig
4. 设置当前上下文
   1. kubectl config use-context system:kube-scheduler --cluster=kubernetes  --kubeconfig=kube-scheduler.kubeconfig 

###### 创建kube-scheduler.conf

​	`vim kube-scheduler.conf`

​	KUBE_SCHEDULER_OPTS="--address=127.0.0.1 \

--kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \

--leader-elect=true \

--alsologtostderr=true \

--logtostderr=false \

--log-dir=/var/log/kubernetes \

--v=2"

###### 创建服务启动文件

vim kube-scheduler.service 

[Unit]

Description=Kubernetes Scheduler

Documentation=https://github.com/kubernetes/kubernetes

 

[Service]

EnvironmentFile=-/etc/kubernetes/kube-scheduler.conf

ExecStart=/usr/local/bin/kube-scheduler $KUBE_SCHEDULER_OPTS

Restart=on-failure

RestartSec=5

 

[Install]

WantedBy=multi-user.target

###### 同步文件&启动服务

在所有的master节点中 同步如下文件

将kube-scheduler-key.pem  kube-scheduler.pem  > /etc/kubernetes/ssl/

将kube-scheduler.kubeconfig  kube-scheduler.conf       > /etc/kubernetes/

将kube-scheduler.service >  /usr/lib/systemd/system/

`ansible master -m copy -a 'src=kube-scheduler-key.pem dest=/etc/kubernetes/ssl/kube-scheduler-key.pem` 

`ansible master -m copy -a 'src=kube-scheduler.pem dest=/etc/kubernetes/ssl/kube-scheduler.pem '`

 `ansible master -m copy -a 'src=kube-scheduler.kubeconfig dest=/etc/kubernetes/kube-scheduler.kubeconfig '`

`ansible master -m copy -a 'src=kube-scheduler.conf dest=/etc/kubernetes/kube-scheduler.conf '`

  `ansible master -m copy -a 'src=kube-scheduler.service dest=/usr/lib/systemd/system/kube-scheduler.service '`

ansible master -m shell -a 'systemctl daemon-reload && systemctl enable kube-scheduler.service && systemctl start kube-scheduler.service '



##### 部署credns

将pasue-coredns 上传到 node1 节点中 通过命令 解压

 docker load -i pause-cordns.tar.gz

##### 部署kubelet

每个Node节点上的kubelet定期就会调用API Server的REST接口报告自身状态，API Server接收这些信息后，将节点状态信息更新到etcd中。kubelet也通过API Server监听Pod信息，从而对Node机器上的POD进行管理，如创建、删除、更新Pod

下面操作在  **master1** 上操作 完成后同步给 **node1**  

###### 创建kulete--bootstrap.kubeconfig

`cd /data/work/`

`BOOTSTRAP_TOKEN=$(awk -F "," '{print $1}' /etc/kubernetes/token.csv)`

 `rm -r kubelet-bootstrap.kubeconfig`  如有

 `kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://192.168.120.180:6443 --kubeconfig=kubelet-bootstrap.kubeconfig`

 `kubectl config set-credentials kubelet-bootstrap --token=${BOOTSTRAP_TOKEN} --kubeconfig=kubelet-bootstrap.kubeconfig`

`kubectl config set-context default --cluster=kubernetes --user=kubelet-bootstrap --kubeconfig=kubelet-bootstrap.kubeconfig`

 `kubectl config use-context default --kubeconfig=kubelet-bootstrap.kubeconfig`

 `kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap`

 

###### 创建配置文件kubelet.json

"cgroupDriver": "systemd"要和docker的驱动一致。

address替换为node1的IP地址， 如有多个node 节点则需要修改每个 kubelet.json 中 address 地址。

 

 vim kubelet.json 

{

 "kind": "KubeletConfiguration",

 "apiVersion": "kubelet.config.k8s.io/v1beta1",

 "authentication": {

  "x509": {

   "clientCAFile": "/etc/kubernetes/ssl/ca.pem"

  },

  "webhook": {

   "enabled": true,

   "cacheTTL": "2m0s"

  },

  "anonymous": {

   "enabled": false

  }

 },

 "authorization": {

  "mode": "Webhook",

  "webhook": {

   "cacheAuthorizedTTL": "5m0s",

   "cacheUnauthorizedTTL": "30s"

  }

 },

 "address": "192.168.120.183",

 "port": 10250,

 "readOnlyPort": 10255,

 "cgroupDriver": "systemd",

 "hairpinMode": "promiscuous-bridge",

 "serializeImagePulls": false,

 "featureGates": {

  "RotateKubeletClientCertificate": true,

  "RotateKubeletServerCertificate": true

 },

 "clusterDomain": "cluster.local.",

 "clusterDNS": ["10.255.0.2"]

}



######  创建kubelet服务启动文件

[root@xianchaomaster1 work]# vim kubelet.service 



[Unit]

Description=Kubernetes Kubelet

Documentation=https://github.com/kubernetes/kubernetes

After=docker.service

Requires=docker.service

[Service]

WorkingDirectory=/var/lib/kubelet

ExecStart=/usr/local/bin/kubelet \

 --bootstrap-kubeconfig=/etc/kubernetes/kubelet-bootstrap.kubeconfig \

 --cert-dir=/etc/kubernetes/ssl \

 --kubeconfig=/etc/kubernetes/kubelet.kubeconfig \

 --config=/etc/kubernetes/kubelet.json \

 --network-plugin=cni \

 --pod-infra-container-image=k8s.gcr.io/pause:3.2 \

 --alsologtostderr=true \

 --logtostderr=false \

 --log-dir=/var/log/kubernetes \

 --v=2

Restart=on-failure

RestartSec=5

 

[Install]

WantedBy=multi-user.target

 

 

\#注： –hostname-override：显示名称，集群中唯一 

–network-plugin：启用CNI 

–kubeconfig：空路径，会自动生成，后面用于连接apiserver

–bootstrap-kubeconfig：首次启动向apiserver申请证书

–config：配置参数文件 

–cert-dir：kubelet证书生成目录 

–pod-infra-container-image：管理Pod网络容器的镜像

###### 同步配置文件创建启动所需目录

**node1 ~]#** mkdir /etc/kubernetes/ssl -p

master1 work]# scp kubelet-bootstrap.kubeconfig kubelet.json xianchaonode1:/etc/kubernetes/

master1 work]# scp  ca.pem xianchaonode1:/etc/kubernetes/ssl/

master1 work]# scp  kubelet.service xianchaonode1:/usr/lib/systemd/system/

###### 启动kubelet服务

node1 ~]#mkdir /var/lib/kubelet

node1 ~]#mkdir /var/log/kubernetes

node1 ~]# systemctl daemon-reload

node1 ~]# systemctl enable kubelet

node1 ~]# systemctl start kubelet

node1 ~]# systemctl status kubelet



###### 在master中批准 node1的bootstrap申请

[root@master1 bin]# kubectl get csr 
NAME                                                   AGE     SIGNERNA
*node-csr-RI4_uwAiq0ovsShhF1t6T0So9LK5ee54KJcqDKTsKyA*   4m32s   kubernet

[root@master1 bin]# kubectl certificate approve node-csr-RI4_uwAiq0ovsShhF1t6T0So9LK5ee54KJcqDKTsKyA
certificatesigningrequest.certificates.k8s.io/node-csr-RI4_uwAiq0ovsShhF1t6T0So9LK5ee54KJcqDKTsKyA approved

[root@master1 bin]# kubectl get csr 
NAME                                                   AGE     SIGNERNAME                                    REQUESTOR           CONDITION
node-csr-RI4_uwAiq0ovsShhF1t6T0So9LK5ee54KJcqDKTsKyA   7m49s   kubernetes.io/kube-apiserver-client-kubelet   kubelet-bootstrap   Approved,Issued
[root@master1 bin]# kubectl get nodes 
NAME    STATUS     ROLES    AGE   VERSION
node1   NotReady   <none>   33s   v1.20.10

##### 部署kube-prox

###### 创建csr请求

vim kube-proxy-csr.json 

{

 "CN": "system:kube-proxy",

 "key": {

  "algo": "rsa",

  "size": 2048

 },

 "names": [

  {

   "C": "CN",

   "ST": "Hubei",

   "L": "Wuhan",

   "O": "k8s",

   "OU": "system"

  }

 ]

}

###### 生成证书

`cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy`

###### 创建kubeconfig 文件

kubectl config set-cluster kubernetes --certificate-authority=ca.pem --embed-certs=true --server=https://192.168.120.180:6443 --kubeconfig=kube-proxy.kubeconfig

创建授权用户

kubectl config set-credentials kube-proxy --client-certificate=kube-proxy.pem --client-key=kube-proxy-key.pem --embed-certs=true --kubeconfig=kube-proxy.kubeconfig

创建上下文

kubectl config set-context default --cluster=kubernetes --user=kube-proxy --kubeconfig=kube-proxy.kubeconfig

配置当前上下文

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

###### 创建kube-proxy 配置文件

vim kube-proxy.yaml 

apiVersion: kubeproxy.config.k8s.io/v1alpha1

bindAddress: 192.168.120.183

clientConnection:

 kubeconfig: /etc/kubernetes/kube-proxy.kubeconfig

clusterCIDR: 192.168.120.0/24  填写虚拟机的cidr

healthzBindAddress: 192.168.120.183:10256

kind: KubeProxyConfiguration

metricsBindAddress: 192.168.120.183:10249

mode: "ipvs"

###### 创建kube-proxy 启动文件

vim kube-proxy.service

[Unit]

Description=Kubernetes Kube-Proxy Server

Documentation=https://github.com/kubernetes/kubernetes

After=network.target

 

[Service]

WorkingDirectory=/var/lib/kube-proxy

ExecStart=/usr/local/bin/kube-proxy \

 --config=/etc/kubernetes/kube-proxy.yaml \

 --alsologtostderr=true \

 --logtostderr=false \

 --log-dir=/var/log/kubernetes \

 --v=2

Restart=on-failure

RestartSec=5

LimitNOFILE=65536

 

[Install]

WantedBy=multi-user.target

###### 同步配置文件

将配置文件和启动文件分别同步至node 节点

scp kube-proxy.service node1:/usr/lib/systemd/system

scp kube-proxy.kubeconfig kube-proxy.yaml node1:/
etc/kubernetes/

创建kube-prox的工作目录

在node1 中执行

mkdir -p /var/lib/kube-proxy

###### 启动kube-proxy服务

在node1 中执行

systemctl daemon-reload

 systemctl enable kube-proxy

systemctl start kube-proxy

##### 部署网络组件-calico组件

在node 节点中部署

###### 将cni.tar  node.tar 上传到node

docker load -i cni.tar.gz 

docker load -i node.tar.gz

###### 将calico.yaml 上传到 master1

 value: "can-reach=192.168.1.131" 这部分可以不用调整

 kubectl apply -f calico.yaml

kubectl get pods -n kube-system   （calico 默认是部署在命名空间 kube-system中）

kubectl get nodes
NAME    STATUS   ROLES    AGE    VERSION
node1   Ready    <none>   135m   v1.20.10

看这里node1节点已经为ready 状态





##### 部署dns组件-coredns

全质量域名FQDN 

kubernetes.default.svc.cluster.local

将coredns.yaml 上传到master1中

`kubectl apply -f coredns.yaml` 

master1 work]# `kubectl get pods -n kube-system`

NAME                       READY   STATUS    RESTARTS   AGE
calico-node-7btw6          1/1     Running   0          10m
coredns-79677db9bd-ptpdd   1/1     Running   0          18s

master1 work]# `kubectl get svc -n kube-system`



##### 测试k8s集群部署tomcat服务

将tomcat 和busybox 上传到node1 中并通过 docker 加载镜像

node1

docker load -i tomcat.tar.gz

docker load -i busybox-1-28.tar.gz 

master1

将tomcat.yaml tomcat-service.yaml 上传 产生一个pod

kubectl apply -f tomcat.yaml 



kubectl apply -f tomcat-service.yaml

查询pod 映射的端口

 kubectl get svc 

NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
kubernetes   ClusterIP   10.255.0.1      <none>        443/TCP          7d
tomcat       NodePort    10.255.194.95   <none>        8080:30080/TCP 

访问node节点的 30080端口如正常的话是可以打开tomcat的。

http://192.168.120.183:30080/



##### 测试cordns 是否正常

master节点上执行

 kubectl run busybox --image busybox:1.28 --restart=Never --rm -it busybox -- sh



 `ping www.baidu.com`

`nslookup kubernetes.default.svc.cluster.local`

`Server:    10.255.0.2`
`Address 1: 10.255.0.2 kube-dns.kube-system.svc.cluster.local`

`Name:      kubernetes.default.svc.cluster.local`
`Address 1: 10.255.0.1 kubernetes.default.svc.cluster.local`



如nslookup 输出的IP 是cordns的 ip则说明 cordns 配置正常

[root@master2 ~]# kubectl get svc -n kube-system 
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   10.255.0.2   <none>        53/UDP,53/TCP,9153/TCP   46h

##### 配置keeplived + nginx 实现k8s apiserver高可用

###### 1.安装nginx 主备

在master1 master2 上   安装之前 准备好 epel.repo

yum -y install nginx keepalived.x86_64  

yum -y install nginx-all-modules.noarch  解决直接install nginx 后不识别stream的问题

`unknown directive "stream" in /etc/nginx/nginx.conf:13`

###### 2.修改nginx配置文件 

**这里nginx 作为反向代理 keeplived作为高可用**

master1 master2 nginx 配置文件相同

`
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

`四层负载均衡，为两台Master apiserver组件提供负载均衡`
stream {

    log_format  main  '$remote_addr $upstream_addr - [$time_local] $status $upstream_bytes_sent';
    
    access_log  /var/log/nginx/k8s-access.log  main;
    
    upstream k8s-apiserver {
       server 192.168.120.180:6443;   # xianchaomaster1 APISERVER IP:PORT
       server 192.168.120.181:6443;   # xianchaomaster2 APISERVER IP:PORT
       server 192.168.120.182:6443;   # xianchaomaster3 APISERVER IP:PORT
    
    }
    
    server {
       listen 16443; # 由于nginx与master节点复用，这个监听端口不能是6443，否则会冲突
       proxy_pass k8s-apiserver;
    }
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    
    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;
    
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;
    
    server {
        listen       80 default_server;
        server_name  _;
    
        location / {
        }
    }
}`

###### 3.配置keepalived 

master1作为主 master2 作为备

下面是主的配置文件

``global_defs {`
   `notification_email {`
     `acassen@firewall.loc`
     `failover@firewall.loc`
     `sysadmin@firewall.loc`
   `}`
   `notification_email_from Alexandre.Cassen@firewall.loc`
   `smtp_server 127.0.0.1`
   `smtp_connect_timeout 30`
   `router_id NGINX_MASTER`
`}`

`vrrp_script check_nginx {`
    `script "/etc/keepalived/check_nginx.sh"`
`}`

`vrrp_instance VI_1 {`
    `state MASTER`
    `interface ens33  # 修改为实际网卡名`
    `virtual_router_id 51 # VRRP 路由 ID实例，同一个vrrp 实例使用唯一的标识，MASTER和BACKUP 的 同一个 vrrp_instance 下 这个标识必须保持一致`
    `**priority** 100    # 优先级，备服务器设置 90`
    `advert_int 1    # 指定VRRP 心跳包通告间隔时间，默认1秒`
    `authentication {`
        `auth_type PASS`
        `auth_pass 1111`
    `}`

`virtual_ipaddress {` 
`192.168.120.199/24`
   `}`
 `track_script {`
 `check_nginx`
    `}`
`}``



备机keepalived配置

`global_defs {`
   `notification_email {`
     `acassen@firewall.loc`
     `failover@firewall.loc`
     `sysadmin@firewall.loc`
   `}`
   `notification_email_from Alexandre.Cassen@firewall.loc`
   `smtp_server 127.0.0.1`
   `smtp_connect_timeout 30`
   `router_id NGINX_BACKUP`
`}`

`vrrp_script check_nginx {`
    `script "/etc/keepalived/check_nginx.sh"`
`}`

`vrrp_instance VI_1 {`
    `state BACKUP`
    `interface ens33`
    `virtual_router_id 51 # VRRP 路由 ID实例， MASTER和BACKUP 的 同一个 vrrp_instance 下 这个标识必须保持一致`
    `**priority** 90`
    `advert_int 1`
    `authentication {`
        `auth_type PASS`
        `auth_pass 1111`
    `}`
    `virtual_ipaddress {`
        `192.168.40.199/24`
    `}`
    `track_script {`
        `check_nginx`
    `}`
`}`

创建一个nginx健康检查的脚本给master 1 2 都同步

`vim /etc/keepalived/check_nginx.sh`

`chmod +x /etc/keepalived/check_nginx.sh`

 `rsync -avz /etc/keepalived/check_nginx.sh master2:/etc/keepalived/`

检查脚本

`#!/bin/bash`
`count=$(ps -ef |grep nginx | grep sbin | egrep -cv "grep|$$")`
`if [ "$count" -eq 0 ];then`
    `systemctl stop keepalived`
`fi`

脚本检测到nginx 停止后会将keepalived 停止  

###### 4.配置开机启动并测试vip 漂移

在master1 master2 上将nginx keepailved配置开机启动

 systemctl enable nginx.service keepalived.service

停止master1 上已经启动的 nginx  可以看到vip 120.199 已经飘到了master2 上 并且keepailved 也停止了

###### 5.修改所有node 节点的配置文件 并  重启服务

使kube-proxy  kubelet 访问vip 地址  

修改如下配置文件



`sed -i 's#192.168.120.180:6443#192.168.120.199:16443#' /etc/kubernetes/kubelet-bootstrap.kubeconfig`

 `sed -i 's#192.168.120.180:6443#192.168.120.199:16443#' /etc/kubernetes/kubelet.json`

`sed -i 's#192.168.120.180:6443#192.168.120.199:16443#' /etc/kubernetes/kubelet.kubeconfig`

`sed -i 's#192.168.120.180:6443#192.168.120.199:16443#' /etc/kubernetes/kube-proxy.yaml`

 `sed -i 's#192.168.120.180:6443#192.168.120.199:16443#' /etc/kubernetes/kube-proxy.kubeconfig`

`systemctl restart kubelet kube-proxy`
检测一下 kubelet kube-proxy 是否正常启动了 
systemctl status kube-proxy.service kubelet.service











