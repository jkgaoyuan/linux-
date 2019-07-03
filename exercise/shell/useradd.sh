#!/usr/bin/env bash
#提示用户输入用户名和密码,脚本自动创建相应的账户及配置密码。如果用户不输入账户名,则提
#示必须输入账户名并退出脚本;如果用户不输入密码,则统一使用默认的 123456 作为默认密码
read -p "输入需要添加的用户" username

if [ -z $username  ]; then
    echo "你必须输入用户"
    exit 2
else
    #开启回显
    stty -echo
read -p "输入需要添加的用户的密码" usernpasswd
    #关闭回显
    stty echo
    if [ -z $usernpasswd ]; then
       usernpasswd=${pass:-123456}   ##写法参考shell笔记:给变量进行备用数值定义
    fi
       #echo $usernpasswd
       useradd $username
       #echo $username
       echo $usernpasswd | passwd --stdin $username
fi
