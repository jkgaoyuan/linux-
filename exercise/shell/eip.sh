###修改虚拟机ip地址  eg: eip 100 修改ip为192.168.1.100
#!/usr/bin/python
import os, sys

def conf_ip(ip):
    iplist = []
    f = open("/etc/sysconfig/network-scripts/ifcfg-eth0", "r+")
    for i in f:
        iplist.append('BOOTPROTO="static"\n' if 'BOOTPROTO=' in i else i)
    iplist.extend(['IPADDR="192.168.1.{0}"\n'.format(ip),'NETMASK="255.255.255.0"\n','GATEWAY="192.168.1.254"\n'])
    f.seek(0,0)
    f.writelines(iplist)
    f.truncate()
    f.close()
if  __name__ == '__main__':
    if  len(sys.argv) == 2 and sys.argv[1].isdigit():
        conf_ip(sys.argv[1])
        os.remove(sys.argv[0])
