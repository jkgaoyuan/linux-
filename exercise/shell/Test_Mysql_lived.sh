#!/usr/bin/env bash
#host 为 检测的MYsql 主机的 ip地址 user 为mysql 用户名 passwd 为密码
host="192.168.1.23"
mysqluser="zabbix"
mysqlpasswd="zabbix"
mysqladmin -h 192.168.1.23 -u '$mysqluser' -p '$mysqlpasswd' ping  & > /dev/null
if [ $? == 0 ]; then
    echo "mysql is UP"
else
    echo "mysql is down"
fi