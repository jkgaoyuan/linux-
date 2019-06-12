#!/usr/bin/env bash
str="abcdefghijklnmopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
pass=""                    ###密码初始为空
for i in {1..8} ; do
    num=$[RANDOM%${#str}]  ###对随机数使用 str 字符数 求余 使产生的随机数小于小于str字符数量
    tmp=${str:$num:1}      ###从str 中取一位字符 开始位置是 num
    pass+=$tmp
done
echo $pass
