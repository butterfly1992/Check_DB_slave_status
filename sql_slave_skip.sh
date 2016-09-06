#!/bin/bash 
#set MySQL Slave's Runnning Status

mysql_binfile=/usr/bin/mysql
mysql_user=root  #MySQL数据库账号
mysql_pass=password  #密码
mysql_sockfile=/var/lib/mysql/mysql.sock
datetime=`date +"%Y-%m-%d/%H:%M:%S"`   #获取当前时间
$mysql_binfile -u$mysql_user -p$mysql_pass -S $mysql_sockfile -e "SLAVE STOP;"
$mysql_binfile -u$mysql_user -p$mysql_pass -S $mysql_sockfile -e "SET GLOBAL SQL_SLAVE_SKIP_COUNTER=1;"
$mysql_binfile -u$mysql_user -p$mysql_pass -S $mysql_sockfile -e "SLAVE START;"
$mysql_binfile -u$mysql_user -p$mysql_pass -S $mysql_sockfile -e "EXIT"
echo "请执行命令：./mysql_slave_status.sh 验证是否开始主从同步，并查看之间差异时间"

