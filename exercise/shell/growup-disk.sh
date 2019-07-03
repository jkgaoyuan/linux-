#!/usr/bin/bash
read -p 'ipaddress  ' ip

        for i in $ip ;
        do
            ssh -X root@$i "LANG=en growpart /dev/vda 1
                            xfs_growfs /dev/vda1"
        done


