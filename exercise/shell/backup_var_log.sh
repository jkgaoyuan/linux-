#!/usr/bin/env bash
tar -czf log.`date+%Y%m%d`.tar.gz /var/log

crontab -e
00 03 * * 5 /root/backup_var_log.sh
