#!/bin/bash

handle_error() {
    echo -e "\e[30m\e[41m ✘ An error occurred during execution at line $BASH_LINENO. \e[0m"
    exit 1
}
trap 'handle_error' ERR

echo -e "\e[30;44m ❍ Downloading Zabbix package. \e[0m"
ubuntu_version=$(lsb_release -rs)
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu${ubuntu_version}_all.deb
sudo dpkg -i "zabbix-release_6.4-1+ubuntu${ubuntu_version}_all.deb"
rm zabbix-release_6.4-1+ubuntu${ubuntu_version}_all.deb

echo -e "\e[30;44m ❍ Installing Zabbix components. \e[0m"
sudo apt update
sudo apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent mysql-server pv -y

if sudo mysql -uroot -e "use zabbix" > /dev/null 2>&1; then
    echo -e "\e[48;5;250m\e[30m ✎ Deleting an existing Zabbix database. \e[0m"
    sudo mysql -uroot -e "DROP DATABASE IF EXISTS zabbix;"
fi
if sudo mysql -uroot -e "use mysql; select user from user where user='zabbix'" | grep zabbix > /dev/null 2>&1; then
    echo -e "\e[48;5;250m\e[30m ✎ Deleting an existing Zabbix user. \e[0m"
    sudo mysql -uroot -e "DROP USER IF EXISTS 'zabbix'@'localhost';"
fi
echo -e "\e[30;44m ❍ Creating the Zabbix database. \e[0m"
pass=$(openssl rand -base64 20)
sudo mysql -uroot <<EOF
create database zabbix character set utf8mb4 collate utf8mb4_bin;
create user zabbix@localhost identified by '$pass';
grant all privileges on zabbix.* to zabbix@localhost;
set global log_bin_trust_function_creators = 1;
EOF

echo -e "\e[30;44m ❍ Decompressing a sql file. \e[0m"
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | pv | mysql --default-character-set=utf8mb4 -uzabbix -p"$pass" zabbix

sudo mysql -uroot <<EOF
set global log_bin_trust_function_creators = 0;
EOF

echo -e "\e[48;5;250m\e[30m ✎ Writing the password to the configuration file. \e[0m"
echo "DBPassword=$pass" | sudo tee -a /etc/zabbix/zabbix_server.conf > /dev/null

echo -e "\e[48;5;183m\e[30m ✶ Starting services. \e[0m"
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2

echo -e "\n=====================\n✔ Zabbix is successfully installed\n- http://host/zabbix\n- DB_NAME: zabbix\n- DB_USER: zabbix\n- Password in the file /etc/zabbix/zabbix_server.conf\n- Admin/zabbix\n=====================\n"
