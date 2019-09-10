#!/usr/bin/env bash
logpath='/usr/local/nginx/logs/'
mv ${logpath}access.log ${logpath}access_$(date -d "yesterday" +"%Y%d%m").log
mv ${logs_path}access.log ${logs_path}access_$(date -d "yesterday" +"%Y%m%d").log
kill -USR1 'cat /usr/local/nginx/logs/nginx.pid'
#发信号给 pid 让重新生成 日志文件
kill -USR1  `cat /usr/local/nginx/logs/nginx.pid`
#echo ${logpath}${filename}
#echo  ${logpath}access_$(date -d "yesterday" +"%Y%m%d").log
