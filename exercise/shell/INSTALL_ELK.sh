#!/usr/bin/env bash
cat << EOF
请确保ip/hosts文件已经配置好,可能会出现错误
EOF
for i in  es2 es3 es4 ; do
    rsync -gpo /etc/yum.repos.d/local.repo root@$i:/etc/yum.repos.d/local.repo
    rsync /etc/hotst root@$i:/etc/hosts
    ssh root@$i "
    yum -y install java-1.8.0-openjdk.x86_64
    yum -y install elasticsearch"

done

