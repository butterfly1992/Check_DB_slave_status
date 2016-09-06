#!/bin/bash 
#Check MySQL Slave's Runnning Status And Record Error Log
#Crontab time 00:05

MYSQLPORT=`netstat -na|grep "LISTEN"|grep "3306"|awk -F[:" "]+ '{print $5}'` #获取数据库端口
MYSQLIP=`ifconfig eth0|grep "inet addr" | awk -F[:" "]+ '{print $4}'`	#获取数据库所在服务器的外网ip
DATA=`date +"%y-%m-%d %H:%M:%S"`	#获取当前系统时间

#监测数据库状态
function checkMysqlStatus(){  
	if [ "$MYSQLPORT" == "3306" ] #判断端口是否正常运行
	then
		/usr/bin/mysql -uroot -ppassword --connect_timeout=5 -e "show databases;" &>/dev/null 2>&1 #将执行结果输出到dev/null文件下，并将错误也输出到此文件内
		if [ $? -ne 0 ]	#判断运行命令的结束代码
		then	#命令代码运行失败，将错误记录日志，并发送邮件
			echo "Server: $MYSQLIP mysql is down, please try to restart mysql by manual!" >> /mnt/mysqlerrlog/mysqlerr.log
			mail -s "WARN! server: $MYSQLIP  mysql is down." admin@qq.com < /mnt/mysqlerrlog/mysqlerr.log
			exit 1
		else	#命令代码运行成功
			echo "mysql is running..."
		fi
	else #端口运行异常，发送邮件，并退出执行脚本
		 echo "WARN!Server: $MYSQLIP mysql is down.$DATA" | mail -s "从库" admin@qq.com
		exit 2
	fi
}
 
checkMysqlStatus #调用数据库状态函数
STATUS=$(/usr/bin/mysql -uroot -ppassword -S /var/lib/mysql/mysql.sock -e "show slave status\G" | grep -i "running")#获取主从信息中含有running的参数
ERRORlog=$(/usr/bin/mysql -uroot -ppassword -S /var/lib/mysql/mysql.sock -e "show slave status\G"| grep -i "Error" )#获取主从信息中含有Error的参数
timeDiff=$(/usr/bin/mysql -uroot -ppassword -S /var/lib/mysql/mysql.sock -e "show slave status\G" | grep -i "Seconds_Behind_Master")#获取主从信息中含有Seconds_Behind_Master的参数
IO_env=`echo $STATUS | grep Slave_IO_Running | awk  ' {print $2}'`	#获取参数Slave_IO_Running的值
SQL_env=`echo $STATUS | grep Slave_SQL_Running | awk  '{print $4}'`	#获取参数Slave_SQL_Running的值
errorlog=`echo $ERRORlog |grep Last_Error`	#获取主从不一致Last_Error的值
secDiff=`echo $timeDiff | grep Seconds_Behind_Master | awk  '{print $2}'`	#获取主从不一致Seconds_Behind_Master的时间差

if [ "$IO_env" = "Yes" -a "$SQL_env" = "Yes" ]	#判断IO和SQL的值是否同时都是YES
then	#控制台打印日志，并将信息记录到日志文件
	 echo "$DATA, MySQL Slave is running![$IO_env;$SQL_env;master-slave-timeDiff:$secDiff Seconds ]"
	 echo "$DATA, MySQL Slave is running![$IO_env;$SQL_env;master-slave-timeDiff:$secDiff Seconds]"  >>    /mnt/mysqlerrlog/mysql_slave_status.log
else	#主从同步不一致，记录信息到日志，并发送邮件到指定邮箱
  echo "####### $DATA #########">> /mnt/mysqlerrlog/mysql_slave_status.log
  echo "MySQL Slave is not running! 【$errorlog】" >>    /mnt/mysqlerrlog/mysql_slave_status.log
  echo "MySQL Slave is not running! errorInfo:【$errorlog】[处理方法：执行/mnt/sqlsh/下的sql_slave_skip.sh脚本文件，跳过此异常，保证同步持续进行，此处BUG会有记录，先保证主从一致]" | mail -s "WARN! $MYSQLIP 从库 is not running." admin@qq.com  
fi
