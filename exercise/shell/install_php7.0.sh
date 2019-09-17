#!/usr/bin/env bash
###正在测试的一键安装php 脚本,
file_name=$1
tar -xf $1
#安装依赖
install_lib()
{
    echo -e "\033[32m正在安装依赖\033[0m"
    yum install -y gcc gcc-c++ make zlib zlib-devel libzip libzip-devel pcre pcre-devel  libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel openssl openssl-devel openldap openldap-devel nss_ldap openldap-clients openldap-servers
#    #解决libzip依赖问题
    yum -y remove libzip
    wget https://libzip.org/download/libzip-1.5.2.tar.gz
    tar -zxvf libzip-1.5.2.tar.gz
    cd libzip-1.5.2
    mkdir build && cd build && cmake .. && make && make install
    cd ..
    echo -e "\033[31m安装依赖完成\033[0m"
}

install_php(){
    echo -e "\033[32m开始安装php\033[0m"
    a=${file_name:0:9}
    cd $a
    ./configure --prefix=/usr/local/php --with-config-file-scan-dir=/usr/local/php/etc/ --enable-inline-optimization --enable-opcache --enable-session --enable-fpm --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-pdo-sqlite --with-sqlite3 --with-gettext --enable-mbregex --enable-mbstring --enable-xml --with-iconv --with-mcrypt --with-mhash --with-openssl --enable-bcmath --enable-soap --with-xmlrpc --with-libxml-dir --enable-pcntl --enable-shmop --enable-sysvmsg --enable-sysvsem --enable-sysvshm --enable-sockets --with-curl --with-curlwrappers --with-zlib --enable-zip --with-bz2 --with-gd --enable-gd-native-ttf --with-jpeg-dir --with-png-dir --with-freetype-dir --with-iconv-dir --with-readline --with-fpm-user=www --with-fpm-group=www
    make && make install
    echo -e "\033[31m安装完成\033[0m"
}

cat << EOF
eg: bash test.sh php-7.3.9.tar.xz
EOF

install_lib
install_php
