#!/usr/bin/env bash
#提示用户输入用户名和密码，脚本自动创建相应的账户及配置密码。
#如果用户不输入账户名，则提 示必须输入账户名并退出脚本；
# 如果用户不输入密码，则统一使用默认的123456作为默认密码。
read -p " pls text UserName: " username
if [ -z $username ]; then
    echo   "ple text UserName "
    exit 2
else
    useradd $username
    #使用stty -echo关闭shell的回显功能

    # 使用stty  echo打开shell的回显功能

    stty -echo
    read -p " pls text UserPasswd " userpasswd
    stty echo

    if [ -z $userpasswd ]; then
        echo " use default passwd 123456"

        echo 123456 | passwd --stdin $username
    else
        echo $userpasswd | passwd --stdin $username

    fi
fi


