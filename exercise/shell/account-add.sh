#!/bin/bash
#这是 鸟哥 书中的一个脚本.13.7.2
# 这个脚本用来批量添加用户和指定家目录并指定初始密码登陆后需要修改密码
# accountadd.txt 是需要添加的用户名文件, 需要提前准备好
# openssl 用来产生密码
# 0. userinputusergroup=""  # if your account need secondary group, add here.
pwmech="openssl"            # "openssl" or "account" is needed. 是否需要指定密码 ,可以为空,默认随机
homeperm="no"               # if "yes" then I will modify home dir permission to 711  修改你对目录的权限
action="$1"
# 检查accountadd 文件是否存在 不存在提示 文件不存在  （判断条件是文件 不存在为真）
# -f 文档存在,且必须文件为真(只能用来筛选文件是否存在) -z 检测变量的值是否为空,空为真
if [ ! -f accountadd.txt  ] ; then
    echo "accountadd.txt not exist"
    exit 2
fi
[ "${usergoup}" !="" ]  && groupadd -r ${usergroup}
rm -f output.txt
usernames=$(cat accountadd.txt)
for username in ${usernames}
do
    case ${action} in
    "create")
            [ "${usergroup}" != "" ] && usegrp="-G ${usergroup}" || usegrp=""     ##|| 逻辑或 前面执行失败后执行后面的
            useradd ${usergroup} ${username}
            [ " ${pwmech}" == "openssl" ] && usepw=$(openssl rand -base64 6) || usepw=${username}
            #产生一个6 位 的 密码
            echo ${usepw} | passwd --stdin ${username} #为用户创建密码
            chage -d 0 ${username}          ##设定密码有效时间 -d 据1970.1.1时间
            [ "${homeperm}"=="yes"  ] && chmod 711 /home/${username}
            echo "username=${username},passwd=${usepw}" >> outputpw.txt
            ;;
        "delete")
            echo "deleting ${username}"
            userdel -r ${username}
            ;;
        *)
            echo "usage: $0 [createldelete]"
            ;;
        esac
done
