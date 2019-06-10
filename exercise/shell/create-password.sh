#!/usr/bin/env bash
str="abcdefghijklnmopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
pass=""
for i in {1..8} ; do
    num=$[RANDOM%${#str}]
    tmp=${str:$num:1}
    pass+=$tmp
done
echo $pass
