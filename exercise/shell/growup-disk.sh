#!/usr/bin/bash
read -p 'ipaddress  ' ip

#if [ $ip -z  ];then
 #  echo 'ipaddress erro, enter ipaddress '
 #  exit 2
  # else
        for i in $ip ;
        do
            ssh -X root@$i "LANG=en growpart /dev/vda 1
                            xfs_growfs /dev/vda1"



        done

#fi
