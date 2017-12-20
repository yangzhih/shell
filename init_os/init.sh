#!/bin/bash
# ----------------+---------------------------------------+
# * Author        : Zachary
# * Email         : zachary_yzh@126.com
# * Create time   : 2017-08-12 02:23
# * Last modified : 2017-08-12 02:23
# * Filename      : test.sh
# * Description   : 
# ----------------+---------------------------------------+

. /etc/init.d/functions

function install()
{
    for i in $@
        do
            rpm -q $i &>/dev/null && passed
            [ "$?" -eq 0 ] && echo "the $i packge installed.." && continue
            yum -y install $i &> /dev/null && success || failure
            echo "install $i packge..."
        done
}


function mount_iso()
{
    mkdir $1 &>/dev/null
    echo "/dev/cdrom  $1 iso9660  loop 0 0" >> /etc/fstab && success || failure
    echo "Auto mount ISO to $1 ... "
    mount -a  && success || failure
    echo "mount the ISO to $1 ..."
}


function cfg_yumrepo()
{
    mkdir /etc/yum.repos.d/bak
    mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
    if [ -e /mnt/cdrom/RPM-GPG-KEY-CentOS-6 ];then
        if [ $os_release -eq $(ls /mnt/cdrom/RPM-GPG-KEY-CentOS-6 |cut -d- -f5) ];then
            printf "[cdrom]\nname=cdrom\nbaseurl=file:///mnt/cdrom\ngpgcheck=0\n" > /etc/yum.repos.d/base.repo
            yum clean all &>/dev/null
            yum list &>/dev/null && success ||failure
            echo  "Config yum repo ..."
            return 0
        else
            warring ||failure
            echo "Please Check your ISO Version ..." && warring ||failure
            return 1
        fi
    fi
}

function cfg_workspace()
{
for i in $@
do
   if `id $i &>/dev/null` ;then
       userhome=$(grep -E "^$i\>" /etc/passwd|cut -d: -f6)
       mkdir -p $userhome/workspace/{scripts,hash,test,tools,docs}
       cp vim.conf $userhome/.vimrc
       chown -R $i.$i $userhome
       success||failure
       echo "Config $i workspace ..."
   else
       useradd $i && echo "$i$i"|passwd --stdin $i &>/dev/null
       success || failure
       echo "Add user $i ..."
       cfg_workspace $i
   fi
done
return
}

function init_service()
{
    for i in `ls /etc/rc3.d/S*`
    do
        CURSRV=`echo $i|cut -c 15-`
#        echo $CURSRV
        case $CURSRV in
            crond | irqbalance | microcode_ctl | network | random | sshd | autofs | syslog | local)
        passed ||failure
        echo "$CURSRV services ...Skip ..."
        ;;
        *)
        success || failure
        echo "Change $CURSRV to off."
        chkconfig --level 235 $CURSRV off
        service $CURSRV stop
        ;;
        esac
     done
}

function cfg_secure_tatics()
{

#Disable Selinux
sed -i "s/SELINUX=enforcing/SELINUX=permissive/g" /etc/sysconfig/selinux
setenforce 0
success || failure
echo "Config SSH tatics ..."

#Disable Root ssh
sed -i "s/#PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
sed -i "s/#PermitEmptyPasswords no/PermitEmptyPasswords no/g" /etc/ssh/sshd_config
sed -i "s/X11Forwarding yes/X11Forwarding no/g" /etc/ssh/sshd_config
sed -i "/^#ListenAddress 0.0.0/a\ListenAddress $1" /etc/ssh/sshd_config
service sshd restart || systemctl restart sshd.service
success || failure
echo "Config SSH tatics ..."

printf "sshd:172.18.0.110\n" >>/etc/hosts.allow
printf "sshd:192.168.2.0/255.255.255.0\n" >>/etc/hosts.allow
printf "sshd:172.18.0.0/255.255.0.0\n" >>/etc/hosts.allow
printf "sshd:ALL\n" >> /etc/hosts.deny
success || failure
echo "Config hosts access control tatics ..."
}


echo -e "\033[36m
+--------------------------------------------------------------+
|         === Welcome to Centos System init ===                |
+--------------------------------------------------------------+
\033[0m"

realpath=`readlink -f "$0"`
basedir=`dirname "$realpath"`
os_release=`grep -o "release [0-9]" /etc/redhat-release |cut -d' ' -f2`

mount_iso /mnt/cdrom
cfg_yumrepo
install  tree lrzsz gcc nmap lftp autofs

cfg_workspace yzh root


echo "alias cdnet='cd /etc/sysconfig/network-scripts/'" >> ~/.bashrc
echo "ntpdate 172.18.0.1" >> /etc/rc.local 
ntpdate 172.18.0.1 && success ||failure
echo "Config ntpdate ..."

echo -en "\E[039mDo you want to Configure Security?\E[0m(yes|no)"
read $answer
if [[ "$answer" =~ [Yy]([Ee][Ss])?$ ]];then
   echo +------------------------------------------------------------------+
    cfg_secure_tatics $(hostname -I)
    if [ "$os_release" -eq 6 ];then
        init_service
    fi
fi
