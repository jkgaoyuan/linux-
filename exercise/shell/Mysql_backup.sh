#!/usr/bin/env bash
##定义变量 user 数据库用户名 passwd 数据库 密码 data 备份时间标签
##dbname 需要备份数据库名称 根据实际改名 默认备份 mysql 库
 没有测试 记得测试
user=root
passwd=123456
dbname=mysql
date=$(date +%Y%m%d)
#测试备份目录是否存在,不存在则自动创建该目录
[ ! -d /mysqlbackup ] &&
mkdir /mysqlbackup
#使用 mysqldump 命令备份数据库
mysqldump -u"$user" -p"$passwd" "$dbname" > /mysqlbackup/"$dbname"-${date}.sql