# kubeadmin 安装多master节点高可用集群

### 准备虚拟机

#### 关闭 swap 分区

swapoff  -a

注销 fstab 中swap的部分

sed -i 's/.*swap.*/#&/' /etc/fstab

#### 关闭selinux

sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

#### 关闭防火墙 安装iptables 并禁用

 systemctl stop firewalld && systemctl disable firewalld

yum install iptables-services -y

service iptables stop  && systemctl disable iptables

#### 修改内核配置文件

```
cat <<EOF > /etc/sysctl.d/k8s.conf

net.bridge.bridge-nf-call-ip6tables = 1

net.bridge.bridge-nf-call-iptables = 1

EOF
```
`sysctl --system`


#### 修改hosts和hostname

hostnamectl set-hostname master1

编辑hosts 文件

#### 修改yum repo 使用阿里云centos-base 、eple 和 docker-ce源

#### 使用桥接网络 & 固定IP

master1-master3 、node 和本机在一个网段且IP分别为

192.168.31.6  master1
192.168.31.16 master2
192.168.31.26 master3
192.168.31.56 node1

#### 配置免密登录

#### 安装ansible  rzsz wget 等常用软件

### 安装 配置 docker

#### **1.查看支持的docker版本**

yum list docker-ce --showduplicates |sort -r

#### **2.在所有的节点上安装最新的docker 版本**

ansible master,node -m shell -a 'yum -y install docker-ce-20.10.8-3.el7'

#### **3.配置开机启动**

 ansible master,node -m shell -a 'systemctl enable docker.service && systemctl start docker.service '

systemctl enable docker.service && systemctl start docker.service 

#### **4.查询docker 状态**

ansible master,node -m shell -a 'systemctl status docker.service |grep running'

#### **5.修改docker配置文件**

yum 安装的docker cgroup driver 默认使用的是  **cgroupfs**， 我们需要将其调整为**systemd**

 docker info  |grep Cgroup
 Cgroup Driver: cgroupfs
 Cgroup Version: 1



存储 使用overlay2

log 最大100mb

使用systemd 管理docker 

`cat > /etc/docker/daemon.json <<EOF`

`{`

 `"exec-opts": ["native.cgroupdriver=systemd"],`

 `"log-driver": "json-file",`

 `"log-opts": {`

  `"max-size": "100m"`

 `},`

 `"storage-driver": "overlay2",`

 `"storage-opts": [`

  `"overlay2.override_kernel_check=true"`

 `]`

`}`

`EOF`

#### 6.同步配置文件  &  重启 docker 服务

`ansible master2,master3,node -m copy -a 'src=/etc/docker/daemon.json dest=/etc/docker/daemon.json'`

`ansible all -m shell -a 'systemctl daemon-reload && systemctl restart docker`

如重启成功则说明配置文件正常。

#### 7.配置内核参数 启动ipvs

不使用swap

开启流量转发

设置网桥包通过iptables

`echo """`

`vm.swappiness = 0`

`net.bridge.bridge-nf-call-iptables = 1`

`net.ipv4.ip_forward = 1`

`net.bridge.bridge-nf-call-ip6tables = 1`

`""" > /etc/sysctl.conf`

`sysctl -p`

配置ipvs

cat > /etc/sysconfig/modules/ipvs.modules <<EOF

\#!/bin/bash

ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_fo ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack"

for kernel_module in \${ipvs_modules}; do

 /sbin/modinfo -F filename \${kernel_module} > /dev/null 2>&1

 if [ $? -eq 0 ]; then

 /sbin/modprobe \${kernel_module}

 fi

done

EOF

chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep ip_vs

### 安装kubernetes1.18

#### 1.  在master和node节点上安装kubeadm和kubelet 并配置开机启动

   1. yum install kubeadm-1.18.2 kubelet-1.18.2 -y

   2. systemctl enable kubelet

      

#### 2.  上传镜像到master 和node 节点  并通过 docker load -i 加载镜像

   1. 1-18-kube-apiserver.tar.gz
   2. 1-18-kube-scheduler.tar.gz
   3. 1-18-kube-controller-manager.tar.gz
   4.  1-18-pause.tar.gz
   5.  1-18-cordns.tar.gz
   6. 1-18-etcd.tar.gz
   7. 1-18-kube-proxy.tar.gz
   8. 可以先上传到 master1  上再通过ansible 将其同步给其他节点

#### 3.  部署keepalived+lvs 实现对master 节点 的 apiserver高可用

   1. ##### 在各master节点上部署keepalived+lvs  

      1. `ansible master -m shell -a 'yum install -y socat keepalived ipvsadm conntrack'`

   2. ##### 修改master1上的 keepalived 配置文件

      1. /etc/keepalived/keepalived.conf

      2. 配置文件修改如下

         1. `global_defs {`

              `router_id LVS_DEVEL`

            `}`

            `vrrp_instance VI_1 {`

              `state BACKUP`

              `nopreempt`

              `interface ens33`

              `virtual_router_id 80`

              `priority 100`

              `advert_int 1`

              `authentication {`

            ​    `auth_type PASS`

            ​    `auth_pass just0kk`

              `}`

              `virtual_ipaddress {`

            ​    `192.168.31.199`

              `}`

            `}`

            `virtual_server 192.168.31.199 6443 {`

              `delay_loop 6`

              `lb_algo loadbalance`

              `lb_kind DR`

              `net_mask 255.255.255.0`

              `persistence_timeout 0`

              `protocol TCP`

              `real_server 192.168.31.6 6443 {`

            ​    `weight 1`

            ​    `SSL_GET {`

            ​      `url {`

            ​       `path /healthz`

            ​       `status_code 200`

            ​      `}`

            ​      `connect_timeout 3`

            ​      `nb_get_retry 3`

            ​      `delay_before_retry 3`

            ​    `}`

              `}`

              `real_server 192.168.31.16 6443 {`

            ​    `weight 1`

            ​    `SSL_GET {`

            ​      `url {`

            ​       `path /healthz`

            ​       `status_code 200`

            ​      `}`

            ​      `connect_timeout 3`

            ​      `nb_get_retry 3`

            ​      `delay_before_retry 3`

            ​    `}`

              `}`

              `real_server 192.168.31.26 6443 {`

            ​    `weight 1`

            ​    `SSL_GET {`

            ​      `url {`

            ​       `path /healthz`

            ​       `status_code 200`

            ​      `}`

            ​      `connect_timeout 3`

            ​      `nb_get_retry 3`

            ​       `delay_before_retry 3`

            ​    `}`

              `}`

            `}`
            
         2. 这里填写的IP需要和虚拟机配置的内网ip相同
         
         3. **将keepalived 模式配置成为非抢占模式 -- nopreempt模式， 这是为了保证 假设master1宕机，启动之后vip不会自动漂移到master1，这样可以保证k8s集群始终处于正常状态，因为假设master1启动，apiserver等组件不会立刻运行，如果vip漂移到master1，那么整个集群就会挂掉，这就是为什么我们需要配置成非抢占模式了**
      
   3. ##### 配置master2节点的 keepalived

         1. 配置文件修改如下
               1. `global_defs {`
                     `router_id LVS_DEVEL`
                  `}`
                  `vrrp_instance VI_1 {`
                      `state BACKUP`
                      `nopreempt`
                      `interface ens33`
                      `virtual_router_id 80`
                      `priority 80`
                      `advert_int 1`
                      `authentication {`
                          `auth_type PASS`
                          `auth_pass just0kk`
                      `}`
                      `virtual_ipaddress {`
                          `192.168.31.199`
                      `}`
                  `}`
                  `virtual_server 192.168.31.199 6443 {`
                      `delay_loop 6`
                      `lb_algo loadbalance`
                      `lb_kind DR`
                      `net_mask 255.255.255.0`
                      `persistence_timeout 0`
                      `protocol TCP`
                      `real_server 192.168.31.6 6443 {`
                          `weight 1`
                          `SSL_GET {`
                              `url {`
                                `path /healthz`
                                `status_code 200`
                              `}`
                              `connect_timeout 3`
                              `nb_get_retry 3`
                              `delay_before_retry 3`
                          `}`
                      `}`
                      `real_server 192.168.31.16 6443 {`
                          `weight 1`
                          `SSL_GET {`
                              `url {`
                                `path /healthz`
                                `status_code 200`
                              `}`
                              `connect_timeout 3`
                              `nb_get_retry 3`
                              `delay_before_retry 3`
                          `}`
                      `}`
                      `real_server 192.168.31.26 6443 {`
                          `weight 1`
                          `SSL_GET {`
                              `url {`
                                `path /healthz`
                                `status_code 200`
                              `}`
                              `connect_timeout 3`
                              `nb_get_retry 3`
                              `delay_before_retry 3`
                          `}`
                      `}`
                  `}`

   4. #####  配置master3节点的 keepalived

         1. 配置文件如下
               1. `global_defs {`
                     `router_id LVS_DEVEL`
                  `}`
                  `vrrp_instance VI_1 {`
                      `state BACKUP`
                      `nopreempt`
                      `interface ens33`
                      `virtual_router_id 80`
                      `priority 30`
                      `advert_int 1`
                      `authentication {`
                          `auth_type PASS`
                          `auth_pass just0kk`
                      `}`
                      `virtual_ipaddress {`
                          `192.168.31.199`
                      `}`
                  `}`
                  `virtual_server 192.168.31.199 6443 {`
                      `delay_loop 6`
                      `lb_algo loadbalance`
                      `lb_kind DR`
                      `net_mask 255.255.255.0`
                      `persistence_timeout 0`
                      `protocol TCP`
                      `real_server 192.168.31.6 6443 {`
                          `weight 1`
                          `SSL_GET {`
                              `url {`
                                `path /healthz`
                                `status_code 200`
                              `}`
                              `connect_timeout 3`
                              `nb_get_retry 3`
                              `delay_before_retry 3`
                          `}`
                      `}`
                      `real_server 192.168.31.16 6443 {`
                          `weight 1`
                          `SSL_GET {`
                              `url {`
                                `path /healthz`
                                `status_code 200`
                              `}`
                              `connect_timeout 3`
                              `nb_get_retry 3`
                              `delay_before_retry 3`
                          `}`
                      `}`
                      `real_server 192.168.31.26 6443 {`
                          `weight 1`
                          `SSL_GET {`
                              `url {`
                                `path /healthz`
                                `status_code 200`
                              `}`
                              `connect_timeout 3`
                              `nb_get_retry 3`
                              `delay_before_retry 3`
                          `}`
                      `}`
                  `}`
               2. 我们可以看到 所有的master keepalived 配置文件指定的vip 和 rs ip 相同， 只有priority 不同。 这里再keepalived 中引入lvs 实现lb 和高可用

   5. 启动mater节点的keepalived & 配置开机启动 & 检测keepalived 服务状态

         1. 启动顺序如下
               1. master1 > master2 > master3
               2. 顺序按照priority数值从大到小
         2. 启动命令
               1. systemctl enable keepalived && systemctl start keepalived && systemctl status keepalived
         3. 检测vip
               1. 启动完成后再master1节点 ip a看下是否存在vip
               2. 又如下 内容则说明以正常完成配置
                     1.   inet 192.168.31.199/32 scope global ens33
               3. ping 192.168.31.199 

#### 4.初始化k8s集群

1. vim kubeadm-config.yaml

   1. apiVersion: kubeadm.k8s.io/v1beta2

      kind: ClusterConfiguration

      kubernetesVersion: v1.18.2

      controlPlaneEndpoint: 192.168.31.199:6443

      apiServer:

       certSANs:

       \- 192.168.31.6

       \- 192.168.31.16

       \- 192.168.31.26

       \- 192.168.31.56

       \- 192.168.31.199

      networking:

       podSubnet: 10.244.0.0/16

      \---

      apiVersion: kubeproxy.config.k8s.io/v1alpha1

      kind: KubeProxyConfiguration

      mode: ipvs

2.  kubeadm  init --config kubeadm-config.yaml 

   1. 执行完成后如出现如下提示则说明初始化完成

   2. ​     To start using your cluster, you need to run the following as a regular user:

       mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config

   3. 保存一下 输出的 ***kubeadm join***的 命令 （在master2 master3  和 node 加入集群时需要用到）

   4. **这一步产生的 token 是存在过期时间的。默认超过1天后将失效，如超过一天在添加其他master会导致添加失败**
   
   5. You can now join any number of control-plane nodes by copying certificate authorities
      and service account keys on each node and then running the following as root:
   
       kubeadm join 192.168.31.199:6443 --token 898nqj.4p7pkm49aloo3hkj \
          --discovery-token-ca-cert-hash sha256:bba5b355af318ef2fb283d885150f1ff845bd1c57c71da05f83d1f0c152ae30b \
          --control-plane

      Then you can join any number of worker nodes by running the following on each as root:
   
      kubeadm join 192.168.31.199:6443 --token 898nqj.4p7pkm49aloo3hkj \
          --discovery-token-ca-cert-hash sha256:bba5b355af318ef2fb283d885150f1ff845bd1c57c71da05f83d1f0c152ae30b

#### 5.部署网络插件calico

##### 		(1)在master1上执行，如下，获取操作k8s资源的权限

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

##### 		(2)分别获取pod 和 node的状态， 可以看到 master1 由于没有 calico 目前是 notready的 

 kubectl get nodes

NAME      STATUS     ROLES    AGE   VERSION
master1   NotReady   master   12m   v1.18.2

kubectl get pods -n kube-system 

##### 		(3)将calico 镜像部署到所有节点上

​		cni.tar.gz   calico-node.tar.gz 

​      `ansible master2,master3,node -m copy -a 'src=/date/ dest=/date/'`

##### 		(4)在各个节点 使用docker load -i 解压镜像

​			 `ansible all -m shell -a 'docker load -i /date/cni.tar.gz &&  docker load -i /date/calico-node.tar.gz'`

#####       (5)下载calico.yaml  并修改

​	git clone https://github.com/luckylucky421/kubernetes1.17.3.git 

将calico yaml中 如下ip 调整为node1 节点的IP

​	IP_AUTODETECTION_METHOD

​	value: "can-reach=192.168.31.56"

​	CALICO_IPV4POOL_CIDR 不修改

##### 	（6）启动calico 并检测 node状态

​	kubectl apply -f calico.yaml

​	kubectl get nodes

确定一下master1 是否ready 

#### 6.同步证书至 m1 m2  并将master2 3 node1 加入节点

##### 		（1）在m2 m3创建存储证书的目录

​		cd /root && mkdir -p /etc/kubernetes/pki/etcd &&mkdir -p ~/.kube/

##### 		（2）将master1节点的证书拷贝到master2 master3 中

`scp /etc/kubernetes/pki/ca.crt master2:/etc/kubernetes/pki/` 

`scp /etc/kubernetes/pki/ca.key master2:/etc/kubernetes/pki/` 

`scp /etc/kubernetes/pki/sa.key master2:/etc/kubernetes/pki/` 

`scp /etc/kubernetes/pki/sa.pub master2:/etc/kubernetes/pki/` 

`scp /etc/kubernetes/pki/front-proxy-ca.crt master2:/etc/kubernetes/pki/`

`scp /etc/kubernetes/pki/front-proxy-ca.key master2:/etc/kubernetes/pki/`

`scp /etc/kubernetes/pki/etcd/ca.crt master2:/etc/kubernetes/pki/etcd/`

`scp /etc/kubernetes/pki/etcd/ca.key master2:/etc/kubernetes/pki/etcd/`

`scp /etc/kubernetes/pki/ca.crt master3:/etc/kubernetes/pki/` 

`scp /etc/kubernetes/pki/ca.key master3:/etc/kubernetes/pki/` 

`scp /etc/kubernetes/pki/sa.key master3:/etc/kubernetes/pki/` 

`scp /etc/kubernetes/pki/sa.pub master3:/etc/kubernetes/pki/` 

`scp /etc/kubernetes/pki/front-proxy-ca.crt master3:/etc/kubernetes/pki/`

`scp /etc/kubernetes/pki/front-proxy-ca.key master3:/etc/kubernetes/pki/`

`scp /etc/kubernetes/pki/etcd/ca.crt master3:/etc/kubernetes/pki/etcd/`

`scp /etc/kubernetes/pki/etcd/ca.key master3:/etc/kubernetes/pki/etcd/`



##### 	（3）在master2 master3 上执行如下命令 将其加入集群

 kubeadm join 192.168.31.199:6443 --token 898nqj.4p7pkm49aloo3hkj \
    --discovery-token-ca-cert-hash sha256:bba5b355af318ef2fb283d885150f1ff845bd1c57c71da05f83d1f0c152ae30b \
    --control-plane

--control-plane 表示 加入master集群

正常执行完成后master2 3 都会出现如下， 以表明已经成功加入集群， 同时也在 2 3 上执行如下

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

[root@master3 ~]# kubectl get nodes 
NAME      STATUS   ROLES    AGE     VERSION
master1   Ready    master   38m     v1.18.2
master2   Ready    master   3m57s   v1.18.2
master3   Ready    master   3m52s   v1.18.2

##### （4）将node1 加入node 节点

在node1中执行如下

kubeadm join 192.168.31.199:6443 --token 898nqj.4p7pkm49aloo3hkj \
    --discovery-token-ca-cert-hash sha256:bba5b355af318ef2fb283d885150f1ff845bd1c57c71da05f83d1f0c152ae30b

完成后再master1 执行 get nodes 可以看到node1 已经加入， 到这一步 k8s已经完成部署了

[root@master1 ~]# kubectl get nodes 
NAME      STATUS   ROLES    AGE     VERSION
master1   Ready    master   44m     v1.18.2
master2   Ready    master   9m53s   v1.18.2
master3   Ready    master   9m48s   v1.18.2
node1     Ready    <none>   26s     v1.18.2



master节点部署的程序

etcd

kube-apiserver

kube-controller-manager

kube-proxy

kube-scheduler

node节点

calico

kube-proxy



[root@master1 ~]# kubectl get pods -n kube-system -o wide 
NAME                              READY   STATUS    RESTARTS   AGE     IP              NODE      NOMINATED NODE   READINESS GATES
calico-node-472vj                 1/1     Running   0          11m     192.168.31.26   master3   <none>           <none>
calico-node-h92rf                 1/1     Running   0          19m     192.168.31.6    master1   <none>           <none>
calico-node-kbncs                 1/1     Running   0          12m     192.168.31.16   master2   <none>           <none>
calico-node-qp74j                 1/1     Running   0          2m37s   192.168.31.56   node1     <none>           <none>
coredns-66bff467f8-65t79          1/1     Running   0          45m     10.244.0.2      master1   <none>           <none>
coredns-66bff467f8-b47gs          1/1     Running   0          45m     10.244.0.3      master1   <none>           <none>
etcd-master1                      1/1     Running   0          46m     192.168.31.6    master1   <none>           <none>
etcd-master2                      1/1     Running   0          11m     192.168.31.16   master2   <none>           <none>
etcd-master3                      1/1     Running   0          11m     192.168.31.26   master3   <none>           <none>
kube-apiserver-master1            1/1     Running   0          46m     192.168.31.6    master1   <none>           <none>
kube-apiserver-master2            1/1     Running   0          12m     192.168.31.16   master2   <none>           <none>
kube-apiserver-master3            1/1     Running   0          11m     192.168.31.26   master3   <none>           <none>
kube-controller-manager-master1   1/1     Running   1          46m     192.168.31.6    master1   <none>           <none>
kube-controller-manager-master2   1/1     Running   0          11m     192.168.31.16   master2   <none>           <none>
kube-controller-manager-master3   1/1     Running   0          11m     192.168.31.26   master3   <none>           <none>
kube-proxy-k5w4l                  1/1     Running   0          11m     192.168.31.26   master3   <none>           <none>
kube-proxy-mlds7                  1/1     Running   0          45m     192.168.31.6    master1   <none>           <none>
kube-proxy-nnrdf                  1/1     Running   0          2m37s   192.168.31.56   node1     <none>           <none>
kube-proxy-nnzbd                  1/1     Running   0          12m     192.168.31.16   master2   <none>           <none>
kube-scheduler-master1            1/1     Running   1          46m     192.168.31.6    master1   <none>           <none>
kube-scheduler-master2            1/1     Running   0          12m     192.168.31.16   master2   <none>           <none>
kube-scheduler-master3            1/1     Running   0          11m     192.168.31.26   master3   <none>           <none>





### 部署其他组件

#### 1.安装**traefik**

​	介绍: traefik 作为一个反向代理 负载均衡工具， 完美的替代了 nginx 再 k8s 中负载均衡的作用。 其本身支持 k8s api 使其具有优势。

​	https://zhuanlan.zhihu.com/p/97420459#:~:text=traefik%20%E4%B8%8E%20nginx,%E4%B8%80%E6%A0%B7%EF%BC%8C%E6%98%AF%E4%B8%80%E6%AC%BE%E4%BC%98%E7%A7%80%E7%9A%84%E5%8F%8D%E5%90%91%E4%BB%A3%E7%90%86%E5%B7%A5%E5%85%B7%EF%BC%8C%E6%88%96%E8%80%85%E5%8F%AB%20Edge%20Router%20%E3%80%82 

​	https://www.php.cn/nginx/422461.html  

​	同步**traefik**镜像至所有的master node 结点， 完成后通过 docker load -i 解压

​	ansible all -m copy -a 'src=/date/traefik_1_7_9.tar.gz dest=/date/traefik_1_7_9.tar.gz'

ansible all -m shell -a 'docker load -i /date/traefik_1_7_9.tar.gz' 

##### 	（1）生成traefik证书，在master1上操作

mkdir  ~/ikube/tls/ -p

生成证书配置文件

echo """

[req]

distinguished_name = req_distinguished_name

prompt = yes

 

[ req_distinguished_name ]

countryName           = Country Name (2 letter code)

countryName_value        = CN

 

stateOrProvinceName       = State or Province Name (full name)

stateOrProvinceName_value    = Beijing

 

localityName           = Locality Name (eg, city)

localityName_value        = Haidian

 

organizationName         = Organization Name (eg, company)

organizationName_value      = Channelsoft

 

organizationalUnitName      = Organizational Unit Name (eg, section)

organizationalUnitName_value   = R & D Department

 

commonName            = Common Name (eg, your name or your server\'s hostname)

commonName_value         = *.multi.io

 

 

emailAddress           = Email Address

emailAddress_value        = lentil1016@gmail.com

""" > ~/ikube/tls/openssl.cnf

生成证书

openssl req -newkey rsa:4096 -nodes -config ~/ikube/tls/openssl.cnf -days 3650 -x509 -out ~/ikube/tls/tls.crt -keyout ~/ikube/tls/tls.key

**secret** 用于存储和管理一些敏感数据，比如密码，token，密钥等敏感信息。它把 Pod 想要访问的加密数据存放到 Etcd 中。然后用户就可以通过在 Pod 的容器里挂载 Volume 的方式或者 环境变量 的方式访问到这些 Secret 里保存的信息

kubectl create -n kube-system secret tls ssl --cert ~/ikube/tls/tls.crt --key ~/ikube/tls/tls.key



##### 	（2）执行yaml 文件  创建tracfik

​		这一步 用clone  (下载calico.yaml 这一步下载的文件)完成仓库中的 tracfik.yaml 通过 如下命令创建 

 kubectl apply -f /date/kubernetes1.17.3/traefik.yaml

查询一下traefik 运行位置 

kubectl get pods -n kube-system -o wide 

 可以看到时每个节点都由的， 这是通过traefik.yaml 中 kind 的参数DaemonSet 指定的。

kind: DaemonSet  这会让每个节点运行pod

https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/

traefik-ingress-controller-6zd4d   1/1     Running   0          46s   192.168.31.56   node1     <none>           <none>
traefik-ingress-controller-p86b2   1/1     Running   0          46s   192.168.31.16   master2   <none>           <none>
traefik-ingress-controller-r5df4   1/1     Running   0          46s   192.168.31.26   master3   <none>           <none>
traefik-ingress-controller-r5twf   1/1     Running   0          46s   192.168.31.6    master1   <none>           <none>

运行完成后直接访问 traefik 的 8080 端口可以看到其dashboard

http://192.168.31.199:8080/dashboard/status



#### 2.安装dashboard 

##### （1）同步镜像

​	ansible all -m copy -a 'src=/date/ dest=/date/'

​	将dashboard_2_0_0.tar.gz 和metrics-scrapter-1-0-1.tar.gz 同步到全部节点上

  完成后通过docker load 解压镜像

ansible all -m shell -a ' docker load -i /date/dashboard_2_0_0.tar.gz && docker load -i /date/metrics-scrapter-1-0-1.tar.gz'

##### （2）下载kubernetes-dashboard.yaml 并启动dashboard

这里用的文件仍然是 下载calico yaml 是的仓库

​	再master1 上执行 如下 部署dashboard

​	  **kubectl apply -f /date/kubernetes1.17.3/kubernetes-dashboard.yaml** 

#####  （3）检测dashboard 是否正常启动

如下则说明已经完成部署

 **kubectl get pods -n kubernetes-dashboard** 

NAME                                         READY   STATUS    RESTARTS   AGE
dashboard-metrics-scraper-694557449d-hghg4   1/1     Running   0          49s
kubernetes-dashboard-5f98bdb684-t27bb        1/1     Running   0          49s

如果pod创建失败， 我们通过kubectl delete pods  kubernetes-dashboard-5f98bdb684-t27bb -n kubernetes-dashboard  

删除后看下是否会重新新建正常的dashboard

镜像的拉取策略是由yaml追踪 如下配置决定的

**imagePullPolicy: IfNotPresent**

#### 3.配置dashboard使之可以通过浏览器访问

##### （1） 查询dashboard前端的service

**kubectl get svc -n kubernetes-dashboard**

NAME                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
dashboard-metrics-scraper   ClusterIP   10.102.225.163   <none>        8000/TCP   17m
kubernetes-dashboard        **ClusterIP**   10.104.69.120    <none>        443/TCP    17m

##### （2） 修改service type类型变成NodePort：

kubectl edit svc kubernetes-dashboard -n kubernetes-dashboard

将type: ClusterIP 替换为type: NodePort

##### （3） 重新检查dashbord 的 service

kubectl get svc -n kubernetes-dashboard

NAME                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)         AGE

kubernetes-dashboard        **NodePort**    10.104.69.120    <none>        443:**30165**/TCP   22m

当前端口为 30165 ， 我们通过 vip 来进行访问 建议通过火狐

https://192.168.31.199:30165/

##### （4） 修改yaml 指定默认的token 登录dashboard

查询**kubernetes-dashboard** 命名空间下的**secret**

**kubectl get secret -n kubernetes-dashboard**

找到如下类似的

kubernetes-dashboard-token-**hg8ch**   kubernetes.io/service-account-token   3      31m

查询kubernetes-dashboard token的信息

**kubectl describe secret kubernetes-dashboard-token-hg8ch -n  kubernetes-dashboard**

保存输出token的部分 将其填入 则可正常登录dashboard了 

eyJhbGciOiJSUzI1NiIsImtpZCI6InVkYVN2VkVVUEd5OEFORzBRSWNRN2t5X1JwTEJTRzR0b0oxMHFwUnR6bHMifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJrdWJlcm5ldGVzLWRhc2hib2FyZC10b2tlbi1oZzhjaCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjhmZDgzZWZiLTg5NTUtNDRiYS1hOTRjLWMwYWQyMjI0MWU2YSIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlcm5ldGVzLWRhc2hib2FyZDprdWJlcm5ldGVzLWRhc2hib2FyZCJ9.Htv-jnhJFh_12WZMR6-UH6BpzZ3ouRB762yHxTTN1pQAsko_-Jq6K-eX9Pp1cOlbai_s_fQeq7QHmJz39SGK-FvL5kdNb44VhV1uOYGaMEuetpom95mObHOOjILatXJNOtboFH1wMHesW_wB2fIa7hd2JH_Iy62MdhcKP7IxxssCgUx8TYL_DgBd_-OzY5EoII2fN-zBeZSpiDnmBFS3GBbL5R7jIpSrsMdDXrqouNhB10HijxPqcc7Stz0e3Dgi8YPtlGqgpmdPHJ2Sjnt67pn1xgN6QUrocaTe9_iK5SEygHAtyddzijsyiIz-Phyn21QrLp9bCiHS7fx8mS30DQ

##### （5）创建管理员token 使其可以查询任何信息

将clusterrolebinding 绑定到 clusterrole 上，使clusterrole 具有所有权限

kubectl create clusterrolebinding dashboard-cluster-admin --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:kubernetes-dashboard

重复第四步的操作 查询 token

kubectl get secret -n kubernetes-dashboard

NAME                               TYPE                                  DATA   AGEkubernetes-dashboard-token-hg8ch   kubernetes.io/service-account-token  



kubectl  describe  secret  kubernetes-dashboard-token-hg8ch  -n   kubernetes-dashboard

保存一下token

eyJhbGciOiJSUzI1NiIsImtpZCI6InVkYVN2VkVVUEd5OEFORzBRSWNRN2t5X1JwTEJTRzR0b0oxMHFwUnR6bHMifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJrdWJlcm5ldGVzLWRhc2hib2FyZC10b2tlbi1oZzhjaCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjhmZDgzZWZiLTg5NTUtNDRiYS1hOTRjLWMwYWQyMjI0MWU2YSIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlcm5ldGVzLWRhc2hib2FyZDprdWJlcm5ldGVzLWRhc2hib2FyZCJ9.Htv-jnhJFh_12WZMR6-UH6BpzZ3ouRB762yHxTTN1pQAsko_-Jq6K-eX9Pp1cOlbai_s_fQeq7QHmJz39SGK-FvL5kdNb44VhV1uOYGaMEuetpom95mObHOOjILatXJNOtboFH1wMHesW_wB2fIa7hd2JH_Iy62MdhcKP7IxxssCgUx8TYL_DgBd_-OzY5EoII2fN-zBeZSpiDnmBFS3GBbL5R7jIpSrsMdDXrqouNhB10HijxPqcc7Stz0e3Dgi8YPtlGqgpmdPHJ2Sjnt67pn1xgN6QUrocaTe9_iK5SEygHAtyddzijsyiIz-Phyn21QrLp9bCiHS7fx8mS30DQ



#### 4.部署metrics

​	metrics作为一个可扩展的监控服务的组件在 k8s中由非常多的应用。 

​	如统计cpu 内存等或者统计每秒请求数 tps， 请求处理耗时  等待处理的队列长度。 

https://www.cnblogs.com/MrRightZhao/p/10975107.html 

###### （1） 将如下同步到所有的节点中 并通过docker load -i 解压

metrics-server-amd64_0_3_1.tar.gz

addon.tar.gz

ansible all -m copy -a 'src=/date/metrics-server-amd64_0_3_1.tar.gz dest=/date/metrics-server-amd64_0_3_1.tar.gz'

ansible all -m copy -a 'src=/date/addon.tar.gz dest=/date/addon.tar.gz'

ansible all -m shell -a 'docker load -i /date/metrics-server-amd64_0_3_1.tar.gz  && docker load -i /date/addon.tar.gz

###### （2）下载metrics.yaml 

这里使用的 metrics.yaml 文件依然为 下载calico yaml 时用到的仓库

/date/kubernetes1.17.3/metrics.yaml 



###### （3）启动metrics

在master1 执行如下

kubectl apply -f /date/kubernetes1.17.3/metrics.yaml

检查一下metrics pod 是否正常启动

kubectl get pods -n kube-system

