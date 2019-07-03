#!/usr/bin/bash
#输入3 个整数,脚本根据数字大小依次排序输出 3 个数字
#num1 中保存最小的数字
#num2 中保存中间的数字
#num3 中保存最大的数字
tmp=0
read -p "输入一个整数" num1
read -p "输入一个整数" num2
read -p "输入一个整数" num3
if [ $num1 -gt $num2 ]; then  ##tmp中取出最大的部分
    tmp=$num1                 ##小的赋值给num1
    num1=$num2                ##大的赋值给num2
    num2=$tmp
fi
if [ $num1 -gt $num3  ]; then
    tmp=$num1
    num1=$num3
    num3=$tmp

fi
if [ $num2 -gt $num3    ]; then
    #tmp=$num3           #将小的取出来
    #num3=$num2          #大的赋值给num3
    #num2=$tmp           #小的赋值给num2

    tmp=$num2           #取出大的
    num2=$num3          #小的给num2
    num3=$tmp           #大的给num3
fi
echo $num1,$num2,$num3