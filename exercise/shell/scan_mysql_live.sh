#!/usr/bin/env bash
#本脚本每2秒检测一次MySQL并发连接数，可以将本脚本设置为开机启动脚本，或在特定时间段执行
# 以满足对MySQL数据库的监控需求，查看MySQL连接是否正常
# 本案例中的用户名和密码需要根据实际情况修改后方可使用

log_file=/var/log/mysql_count.log
user=root
passwd=123456
while :
do
  sleep 2
  count=`mysqladmin  -u  "$user"  -p"$passwd"   status |  awk '{print $4}'`
#  mysqladmin -uroot -pgaoyuan password 'mysql'   注意mysqladmin的格式  详细的 命令可以参考  https://www.cnblogs.com/dadonggg/p/8625500.html
  echo "`date +%Y-%m-%d` 并发连接数为:$count" >> $log_file
done
