#!/usr/bin/env bash

get_messgae()
{
   text=$(lastlog |grep root)

    echo $text

#    curl   https://sc.ftqq.com/SCU8475T3266640a7124a68a84497bf08c3d4603591e866a7f371.send?text=$test
    echo   https://sc.ftqq.com/SCU8475T3266640a7124a68a84497bf08c3d4603591e866a7f371.send?text='$text'

}
#调用函数
get_messgae


#curl   https://sc.ftqq.com/SCU8475T3266640a7124a68a84497bf08c3d4603591e866a7f371.send?text=$message
