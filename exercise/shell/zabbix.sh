#!/bin/bash
#author liukk
#简单的zabbix安装脚本,根据自己的需求可以更改
#使用yum源CentOS7-1804.iso
#Install LNMP architecture
########################检查源码包
jiancha()   {
	export PWD=`pwd` 
        cd $PWD
	bianliang=$(ls | grep $1)
	
	if [ $? -gt 0 ];then
        	echo -e "\033[31m请您提供源码包\033[0m"
        	exit
	else
        	tar -zxvf $bianliang  &>/dev/null
	fi
	}

################### 安装nginx

nginx()	{
	mulu=${1%.tar*}
	cd $PWD/$mulu
	useradd -s /sbin/nologin nginx
	yum install -y gcc pcre-devel openssl-devel
	./configure --user=nginx --group=nginx --with-http_ssl_module --with-http_gzip_static_module --with-http_stub_status_module
	make && make install
	sed -i '65,68s/#//;70s/#//;71s/#//' /usr/local/nginx/conf/nginx.conf
	sed -i '/fastcgi_params/s/fastcgi_params/fastcgi.conf/' /usr/local/nginx/conf/nginx.conf
	echo -e "\033[32m安装路径/usr/local/nginx"
	}
###################安装mariadb与php

 yums()  {
echo -e "\033[32m正在安装php与mariadb软件包,请稍等...\033[0m"
yum install -y mariadb-devel mariadb-server mariadb mariadb-embedded-devel mariadb-embedded php php-fpm php-mysql   &>/dev/null
echo -e "\033[32m已安装完成\033[0m"
	}

################ 启动进程
qidong()
	{
	/usr/bin/systemctl start mariadb
		if [ $? -eq 0 ];then
			echo -e "\033[32mmariadb启动成功\033[0m"
		fi
	 /usr/bin/systemctl start php-fpm
		if [ $? -eq 0 ];then
			echo -e "\033[32mphp启动成功\033[0m"
		fi
	/usr/local/nginx/sbin/nginx
		if [ $? -eq 0 ];then
			echo -e "\033[32mnginx启动成功\033[0m"
		fi
	}
##################安装zabbix
zabbix_server() {
	echo -e "\033[32m正在安装zabbix依赖包,请稍等...\033[0m"
	yum install -y net-snmp-devel libevent-devel curl-devel php-gd php-mbstring php-bcmath php-xml php-ldap
	if [ $? -eq 0 ]; then
		echo -e "\033[32m已安装完成\033[0m"
	else 
		echo -e "\033[31m存在未安装的包,请检查\033[0m"
	fi
	zabbix_mulu=${1%.tar*}
	cd $PWD/$zabbix_mulu
	./configure --prefix=/usr/local/zabbix --enable-server  --enable-proxy  --enable-agent  --with-mysql=/usr/bin/mysql_config    --with-net-snmp    --with-libcurl   &> /dev/null                      
	make && make install 
	mysql -e "create database zabbix character set utf8"
#数据库zabbix用户为zabbix密码为zabbix,需要请自行修改	
	mysql -e "grant all on zabbix.* to zabbix@"localhost" identified by 'zabbix'"
	mysql -uzabbix -pzabbix zabbix <  $PWD/database/mysql/schema.sql
	mysql -uzabbix -pzabbix zabbix <  $PWD/database/mysql/images.sql
	mysql -uzabbix -pzabbix zabbix <  $PWD/database/mysql/data.sql
	cp -a $PWD/frontends/php/* /usr/local/nginx/html/
	chmod -R 777 /usr/local/nginx/html/
	echo -e "\033[32mzabbix安装完成,安装路径/usr/local/zabbix\033[0m"
	}
#########zabbix结合nginx,mysql,php
zabbix_peizhi(){
	sed -i '17a fastcgi_buffers 8 16k;\nfastcgi_buffer_size 32k;\nfastcgi_connect_timeout 300;\nfastcgi_send_timeout 300;\nfastcgi_read_timeout 300;' /usr/local/nginx/conf/nginx.conf
	sed -i '/^post_max_size/s/8/16/;/^max_execution_time/s/30/300/;/^max_input_time/s/60/300/' /etc/php.ini
	sed -i '878a date.timezone =  Asia/Shanghai' /etc/php.ini
	/usr/bin/systemctl restart mariadb
	/usr/bin/systemctl restart php-fpm
	/usr/local/nginx/sbin/nginx -s stop
	/usr/local/nginx/sbin/nginx
}
################ mysql初始化
mysql_server(){
	mysql_secure_installation << EOF

y
bvy8Tabp3Wzc7Ejg
bvy8Tabp3Wzc7Ejg
y
y
y
y
EOF
echo "数据库已经初始化,root密码:bvy8Tabp3Wzc7Ejg"
echo "数据库zabbix用户为zabbix密码为zabbix,需要请自行修改	"
	}
################开启zabbix服务
zabbix_serves(){
	sed -i '/^# DBHost/s/# DBHost/DBHost/' /usr/local/zabbix/etc/zabbix_server.conf	
	sed -i '120a DBPassword=zabbix' /usr/local/zabbix/etc/zabbix_server.conf
	useradd -s /sbin/nologin zabbix
	/usr/local/zabbix/sbin/zabbix_server

	}

######## 主程序
cat << EOF
1 输入nginx源码包的绝对路径,不用解压
2 输入zabbix源码包的绝对路径,不用解压
3 输入zabbix_server,启动zabbix服务端进程
4 不要有骚操作,本脚本很脆弱,经办不起折腾,请将将脚本文件和源码包放在一个文件夹下面,再输入源码报的名字就可以安装了
EOF
read -p "请您输入:" n
soft=${n%%-*} ##%表示从右往左删删除第一个以及后面一个
case $soft in
nginx)
	jiancha $n 
	if [ $? -eq 0 ] ; then
		nginx $n
		sleep 2
		yums
		qidong
	else
                exit
	fi
	;;
zabbix)
	jiancha $n
	if [ $? -eq 0 ] ; then
		zabbix_server $n
		sleep 2
		zabbix_peizhi
		mysql_server
	else
		exit
	fi
	;;
zabbix_server)
	zabbix_serves;;
*)
	echo "\033[31m大哥,输错了\033[0m"
esac
