# Apache CloudStack

[Apache CloudStack] (https://docs.cloudstack.apache.org/en/latest/)

## Instalação

Instalar CloudStack numa máquina virtual sob o hipervisor rodando **Ubuntu**:

```sh
sudo xl create /etc/xen/cloud02.labqs.ita.br.cfg
ssh -p 2222 root@172.31.100.2
```

Obter versão mais recente:

```sh
apt-get update && apt-get upgrade -y
apt-get install -y wget gnupg curl openjdk-11-jdk mysql-server
wget -O- http://download.cloudstack.org/release.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/cloudstack.gpg > /dev/null
echo deb [signed-by=/etc/apt/keyrings/cloudstack.gpg] http://download.cloudstack.org/ubuntu focal 4.17 > /etc/apt/sources.list.d/cloudstack.list
apt-get update
```

Instalar o servidor de gerenciamento

```sh
apt-get install -y cloudstack-management cloudstack-agent cloudstack-usage
systemctl stop cloudstack-agent.service cloudstack-management.service cloudstack-usage.service
```

Editar configurações do banco de dados no arquivo `/etc/mysql/conf.d/cloudstack.cnf`:

```sh
vi /etc/mysql/conf.d/cloudstack.cnf
```

```ini
[mysqld]
server-id=1
sql-mode="STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION,ERROR_FOR_DIVISION_BY_ZERO,NO_ZERO_DATE,NO_ZERO_IN_DATE,NO_ENGINE_SUBSTITUTION"
innodb_rollback_on_timeout=1
innodb_lock_wait_timeout=600
max_connections=1000
log-bin=mysql-bin
binlog-format = 'ROW'
default-authentication-plugin=mysql_native_password
```

Re-iniciar serviço de banco de dados:

```sh
systemctl restart mysql.service
```

Criar banco de dados:

```sh
cloudstack-setup-databases maint:'c0r0n@'@localhost --deploy-as=root -m 'c0r0n@' -k 'c0r0n@' -i 127.0.0.1
```

Configurar rede (verificar nome/IP da interface)

```yaml
network:
  version: 2
  renderer: networkd

  ethernets:
    eth0:
      dhcp4: false
      dhcp6: false

  bridges:
    cloudbr0:
      addresses: [172.31.100.2/16]
      dhcp4: false
      dhcp6: false
      interfaces:
      - eth0
      routes:
      - to: "default"
        via: "172.31.0.1"
      nameservers:
          addresses: [161.24.23.180]
      parameters:
        stp: false
        forward-delay: 0
```

```sh
netplan generate
netplan apply
reboot
```


Iniciar os serviços do **cloudstack**:

```sh
cloudstack-setup-management
```

## Exportar portas

No _host_ expor as seguintes portas:

```sh
sudo iptables -t nat -A PREROUTING -i enp2s0f0 -p tcp -m tcp --dport 80 -j DNAT --to-destination 172.31.100.2:8080
sudo iptables -t nat -A PREROUTING -i enp2s0f0 -p tcp -m tcp --dport 443 -j DNAT --to-destination 172.31.100.2:8443
sudo iptables -t nat -A PREROUTING -i enp2s0f0 -p tcp -m tcp --dport 8250 -j DNAT --to-destination 172.31.100.2:8250
sudo iptables -t nat -A PREROUTING -i enp2s0f0 -p tcp -m tcp --dport 9090 -j DNAT --to-destination 172.31.100.2:9090
sudo iptables-save | sudo tee /etc/iptables/rules.v4
sudo ip6tables-save | sudo tee /etc/iptables/rules.v6
```

Opcional, expor a porta do serviço **MySQL**

```sh
sudo iptables -t nat -A PREROUTING -i enp2s0f0 -p tcp -m tcp --dport 3306 -j DNAT --to-destination 172.31.100.2:3306
```

## Login

Primeiro login no sistema (_usuário_: *admin*, _senha_: *password*)

![Primeiro login](./images/01-cloudstack-login.png)
