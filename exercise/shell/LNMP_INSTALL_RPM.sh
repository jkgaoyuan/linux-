#!/usr/bin/env bash
##依然有优化空间,是指可以在ssh中运行,可提高效率
    echo "安装LNMP并设置默认开机自启;;;"
    read -p "若要继续请输入1  " yes
if [ -z $yes ]; then

    echo "请确认nginx的目录是否存在并且已经安装 gcc pcre-devel openssl-devel 若没有会自动安装 "
        yum -y install gcc pcre-devel openssl-devel
    read -p "输入nginx存放绝对路径" url_nginx

        cd $url_nginx
        cat auto/options | grep YES
    read -p "输入要附加安装的模块用 '\'分隔 或者指定安装路径 或者 其他 若参数为空将默认安装" plug
        ./configure \
        $plug
        make && make install
#使用yum 安装 提前配置好yum源
#服务端使用httpd
#        yum -y install httpd
        yum -y install mariadb mariadb-devel mariadb-server
        yum -y install php php-mysql

        #systemctl start httpd
        #systemctl enable httpd
        systemctl start mariadb
        systemctl enable mariadb
        /usr/local/nginx/sbin/nginx
        echo /usr/local/nginx/sbin/nginx >> /etc/rc.local
#给予 执行权限.若发现开机无法自己则考虑在 /etc/rc.d/rc.local 中添加 /usr/local/nginx/sbin/nginx 并给予x权限
        chmod +x /etc/rc.local
   else
   exit 2
fi
