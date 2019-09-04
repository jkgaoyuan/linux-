#!/usr/bin/bash
#统计 access日志中ip出现的 次数
#将28/Jan/2015全天的访问日志放到a.txt文本
#cat access.log |sed -rn '/28\/Jan\/2015/p' > a.txt 
#统计a.txt里面有多少个ip访问
cat /var/log/httpd/access_log-20190724 |awk '{print $1}'|sort |uniq > ipnum.txt
#通过shell统计每个ip访问次数
for i in `cat ipnum.txt`
do
iptj=`cat /var/log/httpd/access_log-20190724 |grep $i | grep -v 400 |wc -l`
echo "ip地址"$i"在2015-01-28日全天(24小时)累计成功请求"$iptj"次，平均每分钟请求次数为："$(($iptj/1440)) >> result.txt
done


#cat /var/log/httpd/access_log-20190724 |awk '{print $1}'| uniq -c|sort -rn> b.txt
