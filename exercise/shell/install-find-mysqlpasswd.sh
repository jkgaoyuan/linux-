#!/usr/bin/bash
echo "记得先扩容"
echo "参考软件位置/home/student/桌面/NOTE/Firewalls/linux-soft/03/mysql/mysql-5.7.17.tar"
echo "参考软件包名称 mysql-5.7.17.tar"
read -p "输入需要安装数据库服务器ip " ip

read -p"mysql软件位置  " url
read -p"mysql软件名    " name
for i in $ip ; do
    scp $url root@$ip:/root/
    ssh -X root@$ip "tar -xf $name;
    yum -y install mysql-community-*.rpm;
    systemctl restart mysqld;
    systemctl enable mysqld;
    grep 'password' /var/log/mysqld.log
    "
done

