#!/bin/bash
#
#********************************************************************
#Author:		xiaoshuaigege
#github: 	    xiaoshuaigege
#Date: 			2017-10-16
#FileName：		LAMP_Install_Script_CentOS7.3.sh
#URL: 			https://github.com/xiaoshuaigege/LAMP_Install_Script_CentOS7.3
#Description：		The test script
#Copyright (C): 	2017 All rights reserved
#License:        GPL
#********************************************************************
YUM_REPO=/etc/yum.repos.d/lamp.repo
cat > $YUM_REPO << EOF

[yum]
name=centos yum
baseurl=http://mirrors.aliyun.com/centos/7.3.1611/os/x86_64/
gpgcheck=0

[epel]
name=epel yum
baseurl=http://mirrors.aliyun.com/epel/7/x86_64/
gpgcheck=0
		
EOF




#安装开发包组，为编译应用程序做准备
yum groupinstall "development tools" -y


# 源码编译安装HTTPD-2.4
bash /app/Httpd_Install_Script_CentOS7.3.sh

# 二进制代码安装Mariadb
bash /app/Mariadb_Install_Script_CentOS7.3.sh

# 源码编译安装PHP
bash /app/Php_Install_Script_CentOS7.3.sh

# 配置WordPress
bash /app/WordPress_Install_Script_CentOS7.3.sh


