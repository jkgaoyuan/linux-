#统计nginx web日志中访问平凡的url
#日志格式如下
#139.59.189.65 - - [24/Aug/2021:02:35:12 +0800] "GET /index.php HTTP/1.1" 404 153 "-" "-" "-"
#统计nginx访问次数可以看下面文档
#https://blog.csdn.net/weixin_35475608/article/details/112311503
#输出结果如下  也可以配合head taill
#     45 /
#     42 dnspod.qcloud.com:443
#     11 http://azenv.net/
#     11 400
#      7 www.voanews.com:443


#!/bin/bash
read -p '输入log路径  ' log_url
awk '{print $7}'  $log_url |sort |uniq -c |sort -rn
