
# 下载源码文件，并将所有的源码文件存放在 /usr/local/src/目录下
SRC_DIR=/usr/local/src



#下载mariadb
#压缩文件的内容
mariadb_dir=mariadb-10.2.8-linux-x86_64.tar.gz
#解压之后的名称
mariadb_src=mariadb-10.2.8-linux-x86_64
wget https://mirrors.tuna.tsinghua.edu.cn/mariadb//mariadb-10.2.8/bintar-linux-x86_64/$mariadb_dir -P $SRC_DIR 

# 编译安装mariadb
# 1、解压mariadb到指定目录/usr/local/ 并创建mysql软件连接
tar xvf $SRC_DIR/$mariadb_dir  -C /usr/local/
ln -s  /usr/local/$mariadb_src /usr/local/mysql

# 2、创建用户，并指定mysql数据库的存放位置
useradd -r -m -d /app/mysqldb -s /sbin/nologin mysql

# 3、进入到mysql的源码路径利用其提供的脚本工具创建数据
# 这里必须要进入到这个目录，否则会提示出错，提示的错误信息也是说，要进入到这个目录
cd /usr/local/mysql/
./scripts/mysql_install_db --datadir=/app/mysqldb --user=mysql

# 4、创建mysql的配置文件，并修改文件内容
mkdir /etc/mysql

cp /usr/local/mysql/support-files/my-large.cnf  /etc/mysql/my.cnf

# 这里的内容在配置文件中的位置不能乱写

sed -i '/^\[mysqld\]$/a\#指定我们数据库的存储位置\ndatadir = /app/mysqldb\n#将每个表都单独得存储到一个单独的文件中\ninnodb_file_per_table = on\n'  /etc/mysql/my.cnf

# 5、创建myslq的启动脚本，并添加到开机启动
cp /usr/local/mysql/support-files/mysql.server  /etc/rc.d/init.d/mysqld

chkconfig --add mysqld

# 6、创建mysql的日志文件
mkdir /var/log/mariadb
chown mysql /var/log/mariadb/

service mysqld start

# 7、添加mysql的环境变量
mysql_path=/etc/profile.d/mysql.sh
echo 'PATH=/usr/local/mysql/bin/:$PATH' > $mysql_path 

source   $mysql_path  #使变量生效


# 8、创建wordpress应用数据库以及用户，并给用户赋权限
HOSTNAME="localhost"             #数据库信息,也可以指定远程主机
PORT="3306"
USERNAME="root"
PASSWORD=""                #root用户的密码与之前在secure初始化的时候一致

DBNAME="wpdb"                  #数据库名称
TABLENAME=""            #数据库中表的名称

create_db_sql="create database IF NOT EXISTS ${DBNAME}"
# 如果root用户有密码的话，可以使用下面这句
#mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${create_db_sql}"
mysql -h${HOSTNAME} -P${PORT} -u${USERNAME}  -e "${create_db_sql}"

grant_db_sql="grant all on wpdb.* to wpuser@'localhost' identified by 'centos';"
#mysql -h${HOSTNAME} -P${PORT} -u${USERNAME} -p${PASSWORD} -e "${grant_db_sql}"
mysql -h${HOSTNAME} -P${PORT} -u${USERNAME}  -e "${grant_db_sql}"



# 9、进行mysql的安全初始化，这里需要手动操作,这一步操作，可以自己后续进行
#cd /usr/local/mysql/

#mysql_secure_installation

#cd
