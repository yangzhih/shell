
# 下载源码文件，并将所有的源码文件存放在 /usr/local/src/目录下
SRC_DIR=/usr/local/src
HTTPD_DOCS=/app/httpd24/htdocs

#下载wordpress
#压缩文件的内容
wordpress_dir=wordpress-4.8.1-zh_CN.tar.gz
#解压之后的文件内容
wordpress_src=wordpress
wget https://cn.wordpress.org/$wordpress_dir -P $SRC_DIR  



# 编译安装mariadb
# 1、解压mariadb到指定目录/usr/local/ 并创建mysql软件连接
tar xvf $SRC_DIR/$wordpress_dir   -C  $HTTPD_DOCS/



cp  $HTTPD_DOCS/$wordpress_src/wp-config-sample.php  $HTTPD_DOCS/$wordpress_src/wp-config.php


sed -i   "s/define('DB_NAME', 'database_name_here')/define('DB_NAME', 'wpdb')/"   $HTTPD_DOCS/$wordpress_src/wp-config.php

sed -i   "s/define('DB_USER', 'username_here')/define('DB_USER', 'wpuser')/"   $HTTPD_DOCS/$wordpress_src/wp-config.php

# 这里的密码，与创建数据库时的密码一致
sed -i   "s/define('DB_PASSWORD', 'password_here')/define('DB_PASSWORD', 'centos')/"   $HTTPD_DOCS/$wordpress_src/wp-config.php

# 默认不用替换，默认使用localhost，如果是安装在独立主机上的话，这里要修改一下
#sed -i   "s/define('DB_HOST', 'localhost')/define('DB_HOST', '172.18.2.77')/"   $HTTPD_DOCS/$wordpress_src/wp-config.php


echo "安装已完成，请使用浏览器访问http://webserv/wordpress/来进行wordPress初始化"

exit
