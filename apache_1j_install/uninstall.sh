#!/bin/bash
# ----------------+---------------------------------------+
# * Author        : Zachary
# * Email         : zachary_yzh@126.com
# * Create time   : 2017-08-03 23:31
# * Last modified : 2017-08-03 23:31
# * Filename      : uninstall.sh
# * Description   : 
# ----------------+---------------------------------------+

echo -e "\e[34mplease enter you apache path:\e[0m\c"
read prefix
echo -e "\e[35m\e[7mDo you go to continue?: \e[0m\c" 
read code
if [[ "$code" =~ [yY]([eE][sS])?$ ]];then
    echo
else
    echo "Please run install.sh again."
    exit 2
fi

rm -rf $prefix
rm -f /etc/init.d/httpd
rm -f /etc/profile.d/httpd.sh

