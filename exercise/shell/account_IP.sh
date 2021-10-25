#统计一下 web服务器的访问IP 的前10 位
# 如日志格式如下
# 186.201.222.42 - - [24/May/2020:03:09:46 +0800] "GET / HTTP/1.1" 403 4897 "-" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"
#输出结果如下

#    949 123.58.8.34
#     49 195.54.160.123
#     16 218.206.249.133

#!/bin/bash
read -p '输入logdurl  ' url  #要求输入log路径
awk {'print $1'} $url |sort |uniq -c |sort -nr|head -10