#!/usr/bin/bash
##这个脚本的目的是切割nginx日志文件
##取得的当前时间.注意反撇号 ``
 date=`date +%Y%m%d`
 logpath=/usr/local/nginx/logs
 mv $logpath/access.log $logpath/access-$date.log
 mv $logpath/error.log $logpath/error-$date.log
 ## kill USR1 PID(nginx的进程PID号)   kill,(设计用来传递信息), 命令有许多功能 杀进程只是其中一个
 ##发送kill -USR1信号给Nginx的主进程号，让Nginx重新生成一个新的日志文件
 ##在linux系统中，linux是通过信号与”正在运行的进程”进行通信的,每个软件预设的信号是不相同的,具体查阅 相关软件说明.
 ##nginx.pid 当nginx 启动后会自动将pid写入该文件
 kill -USR1 $(cat $logpath/nginx.pid)
 ##定时任务 在terminal 中输入
 #crontab -e
 #03 03 * * 5  /usr/local/nginx/cut_nginx_log.sh
