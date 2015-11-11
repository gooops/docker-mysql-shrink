#!/bin/bash
#根据需要初始化MySQL
MYSQL_USER=${MYSQL_USER:-mysql}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c6)}
MYSQL_DATABASE=${MYSQL_DATABASE:-test}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10)}

#修改默认端口
sed -ri "s/(^port.*=[^0-9]*)([0-9]*)/\1${MYSQL_PORT}/g" /usr/local/mysql/etc/my.cnf

#启动mysql
su mysql -s /etc/init.d/mysqld start

echo "=> Initialize the MySQL ${MYSQL_PORT}"
echo "==============================================================================="
echo "=> Creating Database ${MYSQL_DATABASE}"
/usr/local/mysql/bin/mysql -h 127.0.0.1 -P${MYSQL_PORT} -uroot -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE}"
echo "=> Creating MySQL ${MYSQL_USER} user with ${MYSQL_PASSWORD} password"
/usr/local/mysql/bin/mysql -h 127.0.0.1 -P${MYSQL_PORT} -uroot -e "grant all privileges on ${MYSQL_DATABASE}.* to '${MYSQL_USER}'@'%' identified by '${MYSQL_PASSWORD}'";
echo "=> Creating MySQL root user with ${MYSQL_ROOT_PASSWORD} password"
/usr/local/mysql/bin/mysql -h 127.0.0.1 -P${MYSQL_PORT} -uroot -e "update mysql.user set authentication_string=PASSWORD('${MYSQL_ROOT_PASSWORD}') where user='root' and host='localhost';flush privileges;";
echo "==============================================================================="
echo "=> Done!"
#停止mysql
/etc/init.d/mysqld stop
sed -i "/'start'/,/'stop'/s/\&$//g" /etc/init.d/mysqld
chown -R mysql.mysql /data/mysql

#启动
/usr/bin/supervisord
