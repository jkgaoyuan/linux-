#!/usr/bin/bash
### 备份 /var/log 下的所有 日志文件
tar -czf log.`date +%Y%m%d`.tar.gz /var/log
##定时每周五的 3:00 执行
crontab -e
00 03 * * 5 /root/backup_var_log.sh
