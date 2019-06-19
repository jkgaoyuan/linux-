#!/usr/bin/bash
echo "产生ssh-key,传递给服务器实现无秘钥登录"
read -p "输入产生公钥的服务器ip " master_server
read -p "接受公钥服务器ip  " slave_server
ssh -X root@$master_server "ssh-keygen   -f /root/.ssh/id_rsa    -N '';
for i in $slave_server
do
echo 1
ssh-copy-id -f $i  #####这句话不执行
echo 2
done
"
