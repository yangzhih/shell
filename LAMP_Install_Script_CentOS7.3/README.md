# 使用方法
创建一个干净的CentOS7.3的主机。
在根目录下创建一个app目录，将下载后的脚本放在app目录下，如下所示。
```shell
[root@localhost app]#tree
.
├── Httpd_Install_Script_CentOS7.3.sh
├── LAMP_Install_Script_CentOS7.3.sh
├── Mariadb_Install_Script_CentOS7.3.sh
├── Php_Install_Script_CentOS7.3.sh
└── WordPress_Install_Script_CentOS7.3.sh

```
然后调用如下方法
```shell
bash /app/LAMP_Install_Script_CentOS7.3.sh
```
系统就会自动安装了

# 脚本介绍  

```shell

#配置了yum源
#安装了开发包组
#调用其它脚步
LAMP_Install_Script_CentOS7.3.sh  



# 下载安装HTTPD，并对其进行配置
Httpd_Install_Script_CentOS7.3.sh


# 下载安装MariaDB，并对其进行配置，里面的某些内容，需要根据自己的实际情况来进行修改
# 例如，创建的WordPress数据库
Mariadb_Install_Script_CentOS7.3.sh


# 下载安装PHP，需要对HTTPD的配置文件进行修改，
# 因此，如果要自己修改选项的话，要记住自己在HTTPD安装的过程中的配置
Php_Install_Script_CentOS7.3.sh

# 下载安装WordPress，与Httpd的安装和配置有关
WordPress_Install_Script_CentOS7.3.sh

```

# 最终的实现效果

![LAMP最终的实现效果](http://ot2trm1s2.bkt.clouddn.com/LAMP-INSTALL.png)

# 参考连接
[http://www.pojun.tech/blog/2017/10/11/linux-middle-command-8](http://www.pojun.tech/blog/2017/10/11/linux-middle-command-8 "刀剑尚未备好，转身已是江湖")

[http://xiaoshuaigege.blog.51cto.com/6217242/1971597](http://xiaoshuaigege.blog.51cto.com/6217242/1971597 "救火队长") 

[http://blog.csdn.net/eumenides_s/article/details/78209282]( http://blog.csdn.net/eumenides_s/article/details/78209282 "Eumenides_s")

# 接下来需要完善的地方
- 网络资源的有效性没有经过验证。如果网络资源出现问题，脚本将不可用  
- 没有友好的提示界面，错误信息没有友好的输出。为了调试的方便，默认所有的输出到控制台。  
- 没有进行版本的适配，目前，此脚本只适用于CentOS7.3,以及编译安装的方式。其他平台不可行。  
- 不支持删除回滚等基本操作。  
- 安装路径不灵活，目前只能在/app/目录下进行安装。  
- 用户自定义程度很低，如果要自己指定相关配置，需要手动修改shell脚本，对于不熟练的朋友来说，略有难度。   




# 备注  

本项目已经收录进我的另外一个Repository，[Collection-of-Linux-Bash-Scripts](https://github.com/xiaoshuaigege/Collection-of-Linux-Bash-Scripts "https://github.com/xiaoshuaigege/Collection-of-Linux-Bash-Scripts")，欢迎star&follow


