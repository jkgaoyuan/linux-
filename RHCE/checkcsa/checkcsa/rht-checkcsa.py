#!/usr/bin/env python
#*-* coding: utf-8 *-*

import os


if  not os.system('ping -c 1 server0 &> /dev/null'):
    if not os.system('scp .checkcsa root@server0:/root/.checkcsa &> /dev/null'):
        mess = """
# Input(1):         check_all        完整测试(测试所有项)
# Input(ENTER):     check_no_user    部分测试(不包含用户密码的验证)

检查结果完全参照 RHCSA  ANSWER PDF
Please Input(1 or ENTER) : """
        print mess
        os.system('ssh root@server0 "python /root/.checkcsa"')
    else:
        print  'Cat`t ssh server0 ,transfer script files failed'
        os._exit(2)
else:
    print 'Ping server0 failed'
    os._exit(1)

