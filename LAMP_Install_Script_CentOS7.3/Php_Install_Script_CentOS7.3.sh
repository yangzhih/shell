
# 下载源码文件，并将所有的源码文件存放在 /usr/local/src/目录下
SRC_DIR=/usr/local/src



# 下载php并且进行重命名
#压缩文件的内容
php_dir=php-7.1.10.tar.xz
#解压之后的内容
php_src=php-7.1.10
wget http://hk1.php.net/get/$php_dir/from/this/mirror  -O $SRC_DIR/$php_dir

#安装所需要的依赖包
yum install libxml2-devel bzip2-devel libmcrypt-devel -y

# 编译安装mariadb
# 1、解压mariadb到指定目录/usr/local/ 并创建mysql软件连接
tar xvf $SRC_DIR/$php_dir   -C  $SRC_DIR/

# 2、配置编译选项

cd $SRC_DIR/$php_src
# 配置编译选项
./configure \
--prefix=/app/php \
--enable-mysqlnd \
--with-mysqli=mysqlnd \
--with-openssl \
--with-pdo-mysql=mysqlnd \
--enable-mbstring \
--with-freetype-dir \
--with-jpeg-dir \
--with-png-dir \
--with-zlib \
--with-libxml-dir=/usr \
--enable-xml \
--enable-sockets \
--with-apxs2=/app/httpd24/bin/apxs \
--with-mcrypt \
--with-config-file-path=/etc \
--with-config-file-scan-dir=/etc/php.d \
--enable-maintainer-zts \
--disable-fileinfo


make -j 2 && make install

# 3、准备PHP配置文件
cp php.ini-production /etc/php.ini

# 4、修改Httpd配置文件，使其支持php
sed -i "s/DirectoryIndex index.html/DirectoryIndex index.html index.php/" /etc/httpd24/httpd.conf

sed -i '/^<IfModule mime_module>$/a\AddType application/x-httpd-php .php\nAddType application/x-httpd-php-source .phps\n'  /etc/httpd24/httpd.conf

# 重新启动HTTPD
apachectl restart 

# 退回到家目录
cd  






