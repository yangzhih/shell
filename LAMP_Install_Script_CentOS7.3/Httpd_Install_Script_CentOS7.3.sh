# 下载源码文件，并将所有的源码文件存放在 /usr/local/src/目录下
SRC_DIR=/usr/local/src


#下载httpd2.4
#压缩文件的名称
http_dir=httpd-2.4.28.tar.bz2
#解压之后的名称
http_src=httpd-2.4.28
wget http://mirrors.tuna.tsinghua.edu.cn/apache//httpd/$http_dir  -P $SRC_DIR 

#下载apr
#压缩文件的名称
apr_dir=apr-1.6.2.tar.bz2
#解压之后的名称
apr_src=apr-1.6.2
wget http://mirrors.tuna.tsinghua.edu.cn/apache//apr/$apr_dir -P $SRC_DIR  

#下载apr-util
#压缩文件的名称
apr_util_dir=apr-util-1.6.0.tar.bz2 
#加压之后的名称
apr_util_src=apr-util-1.6.0
wget http://mirrors.tuna.tsinghua.edu.cn/apache//apr/$apr_util_dir -P $SRC_DIR  



# 源码编译安装HTTPD-2.4
# 1、解压源码文件
tar xvf $SRC_DIR/$apr_dir -C  $SRC_DIR/
tar xvf $SRC_DIR/$apr_util_dir -C $SRC_DIR/
tar xvf $SRC_DIR/$http_dir -C  $SRC_DIR/
# 2、将解压后的apr和apr-util包拷贝到httpd目录下
cp -r $SRC_DIR/$apr_src  $SRC_DIR/$http_src/srclib/apr
cp -r $SRC_DIR/$apr_util_src $SRC_DIR/$http_src/srclib/apr-util

# 3、安装所需要的额外的软件包
yum install openssl-devel expat-devel pcre-devel  -y

# 4、进入到httpd解压目录进行编译安装
cd $SRC_DIR/$http_src
# 配置编译选项
./configure \
--prefix=/app/httpd24 \
--sysconfdir=/etc/httpd24 \
--enable-so \
--enable-ssl \
--enable-rewrite \
--with-zlib \
--with-pcre \
--with-included-apr \
--enable-modules=most \
--enable-mpms-shared=all \
--with-mpm=prefork

#进行安装
make -j 2 && make install

# 5、将应用程序添加到环境变量中，并启动服务
cd
http_path=/etc/profile.d/http.sh
echo 'PATH=/app/httpd24/bin/:$PATH' > $http_path 

source  $http_path    #使变量生效

apachectl start #启动服务


