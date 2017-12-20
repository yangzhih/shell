#!/bin/bash
# ----------------+---------------------------------------+
# * Author        : Zachary
# * Email         : zachary_yzh@126.com
# * Create time   : 2017-08-04 09:45
# * Last modified : 2017-08-04 09:45
# * Filename      : install.sh
# * Description   : 
# ----------------+---------------------------------------+

os_release=`grep -o "release [0-9]" /etc/redhat-release |cut -d' ' -f2`


yum install -y gcc apr apr-devel apr-util apr-util-devel pcre-devel openssl openssl-devel 
if [ "$?" -eq 0 ];then
    echo  -e "\e[34mBase Configure is OK !\e[0m"
else
    echo -e "\e[34m\e[5mBase Configure is failure,Please check your yum config!\e[0m"
    exit 100
fi

echo -e "\e[34mPlease enter a path whith you want to installed: \e[0m\c" 
read prefix
echo
echo -e "\e[35m\e[7mDo you go to continue?: \e[0m\c" 
read code
if [[ "$code" =~ [yY]([eE][sS])?$ ]];then
    echo
else
    echo "Please run install.sh again."
    exit 2
fi

if [ "$os_release" -eq 6 ];then
#    tar -xvf httpd-2.2.34.tar.bz2
    cd httpd-2.2.34
    echo "MANPATH       $prefix/man" >> /etc/man.config
else
#    tar -xvf httpd-2.4.27.tar.bz2
    cd httpd-2.4.27
    echo "MANDATORY_MANPATH         $prefix/man" >> /etc/man_db.conf
fi

./configure --prefix=/usr/local/httpd  --enable-ssl && make && make install
if [ "$?" -eq 0 ];then
    echo  "export PATH=$prefix/bin:$PATH" > /etc/profile.d/httpd.sh
    source /etc/profile.d/httpd.sh
    ln -s  $prefix/bin/apachectl /etc/init.d/httpd 
fi

