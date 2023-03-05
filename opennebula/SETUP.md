

```bash
wget -q -O- https://downloads.opennebula.org/repo/repo2.key | sudo apt-key add -


sudo apt update

sudo apt -y install mariadb-server
sudo mysql_secure_installation

sudo adduser --disabled-password --gecos "" oneadmin
sudo usermod --password $(echo c0r0n@ | openssl passwd -1 -stdin) oneadmin


sudo mysql -u root -p
DROP DATABASE opennebula;
CREATE DATABASE opennebula;
GRANT ALL PRIVILEGES ON opennebula.* TO 'oneadmin' IDENTIFIED BY 'c0r0n@';
FLUSH PRIVILEGES;
EXIT;

sudo apt --yes install opennebula opennebula-sunstone opennebula-gate opennebula-flow

sudo vi /etc/one/oned.conf
DB = [ backend = "mysql",
server = "localhost",
port = 0,
user = "oneadmin",
passwd = "c0r0n@",
db_name = "opennebula" ]


sudo ufw allow proto tcp from any to any port 9869

sudo su - oneadmin
echo "oneadmin:c0r0n@" > ~/.one/one_auth

sudo systemctl start opennebula opennebula-sunstone

sudo systemctl enable opennebula opennebula-sunstone

systemctl status opennebula.service

journalctl -xeu opennebula.service


sudo apt --yes --purge remove mariadb-server mysql-server
sudo apt --yes --purge remove opennebula opennebula-sunstone opennebula-gate opennebula-flow
sudo apt --yes autoremove
sudo userdel oneadmin
sudo rm -rf /var/lib/one
```