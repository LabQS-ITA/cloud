# Xen Project

## Pré instalação Ubuntu

### Ajustar `hosts`

No arquivo `/etc/hosts`, eliminar linha

```
127.0.1.1 <nome do host>
```

### Atualizar sistema

```bash
sudo apt update -y && apt upgrade -y
```
### Criar usuários

```bash
sudo adduser --disabled-password --gecos "" gpes
sudo usermod --password $(echo c0r0n@ | openssl passwd -1 -stdin) gpes
sudo usermod -a -G sudo gpes
```

#### Autorizar para sudo

```bash
echo "gpes ALL=(ALL:ALL) ALL" | sudo tee /etc/sudoers.d/gpes
```

## Instalar Xen Hypervisor

```bash
sudo apt-get install -y xen-hypervisor-amd64
sudo reboot
```

### Configurar memória Xen

Arquivo `/etc/default/grub.d/xen.cfg`

Opção com 4Gb:

```ini
GRUB_CMDLINE_XEN_DEFAULT="dom0_mem=4096M,max:4096M"
```

Opção com 10Gb:

```ini
GRUB_CMDLINE_XEN_DEFAULT="dom0_mem=10794M,max:10794M"
```

```bash
sudo update-grub
sudo reboot
```

### Xen-Tools

```bash
sudo apt install -y xen-tools
```

## Configurar redes

Instalar utilitários

```bash
sudo apt install -y iptables-persistent
```

### Gateway interno

Arquivo `/etc/sysctl.conf`, remover o comentário da linha:

```ini
net.ipv4.ip_forward = 1
net.ipv4.conf.enp2s0.proxy_arp = 1
```

Atualizar com o comando

```bash
sudo sysctl -p
```

Adicionar *NAT* _forwarding_ evitando que **systemd-resolved** entre em conflito com o mapeamento (opção *! -o lo*)

```bash
sudo iptables ! -o lo -t nat -A POSTROUTING -j MASQUERADE
sudo dpkg-reconfigure iptables-persistent
```

```bash
vi /etc/modules-load.d/br_netfilter.conf
```

`/etc/modules-load.d/br_netfilter.conf`

```conf
br_netfilter
```



 #### Excluir regras

Listar a regra

 ```bash
 sudo iptables -L -t nat --line-numbers
 ```

Excluir pelo número da linha

```bash
sudo iptables -t nat -D POSTROUTING 1
```


### Configuração serviço DHCP

#### Opção ISC-DHCP

Instalar serviço *ISC-DHCP*

```bash
sudo apt install -y isc-dhcp-server
```

Arquivo `/etc/default/isc-dhcp-server` ligado à _bridge_ para o _hypervisor_ de máquinas virtuais e a interface de rede física associada à _bridge_ (ver arquivo `/etc/netplan/00-default.yaml`).

```ini
DHCPDv4_CONF=/etc/dhcp/dhcpd.conf
INTERFACESv4="xenbr0 enp2s0f1"
INTERFACESv6=""
```

Arquivo `/etc/dhcp/dhcpd.conf` define um _pool_ de endereços para as máquinas virtuais cujo nome de _host_ iniciem por `labqs`.

```ini
option domain-name "labqs.ita.br";
option domain-name-servers 161.24.23.180, 161.24.23.199; #ns1.example.org, ns2.example.org;

default-lease-time 600;
max-lease-time 7200;

ddns-update-style none;
deny declines;
deny bootp;

class "labqs" {
    match if ( substring( option host-name, 0, 8 ) = "labqs" );
}

subnet 10.0.0.0 netmask 255.0.0.0 {
    authoritative;
    option routers 10.0.0.1;
    pool {
        range 10.0.0.100 10.0.0.254;
        allow members of "labqs";
    }
}
```

#### Opção DNSMASQ

Criar arquivo `\etc\resolv-dnsmasq.conf` (isto resolve problema ao desligar serviço *resolvd*).

```bash
sudo cp /etc/resolv.conf /etc/resolv-dnsmasq.conf
```

Instalar serviço *DNSMASQ*.

```bash
systemctl stop systemd-resolved
systemctl mask systemd-resolved

sudo apt install -y dnsmasq
```

Arquivo `/etc/resolv-dnsmasq.conf`

```
nameserver 127.0.0.53
nameserver 161.24.23.180
nameserver 161.24.23.199
options edns0 trust-ad
```

Arquivo `/etc/dnsmasq.conf`.

```ini
port=53

domain-needed
bogus-priv

resolv-file=/etc/resolv-dnsmasq.conf

interface=xenbr0
listen-address=10.10.0.1
domain=labqs.ita.br
dhcp-range=10.10.0.100,10.10.0.254,255.255.0.0
dhcp-option=3,10.10.0.1
dhcp-lease-max=253

cache-size=1000
```

Arquivo `/etc/netplan/00-default.yaml` define os endereços fixos das duas interfaces de rede, sendo que uma delas é associada à _bridge_ ligada ao _hypervisor_.

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp2s0:
      dhcp4: false
      dhcp6: false
  bridges:
    xenbr0:
      addresses:
      - "161.24.2.234/24"
      nameservers:
        addresses:
        - 161.24.23.180
        - 161.24.23.199
      dhcp4: false
      dhcp6: false
      interfaces:
      - vlan10
      routes:
      - metric: 100
        to: "default"
        via: "161.24.2.1"
      - metric: 100
        table: 100
        to: "161.24.2.0/24"
        via: "161.24.2.1"
      routing-policy:
      - table: 100
        from: "161.24.2.0/24"
  bonds:
    bond0:
      dhcp4: false
      dhcp6: false
      interfaces:
      - enp2s0
  vlans:
    vlan10:
      dhcp4: false
      dhcp6: false
      id: 10
      link: "bond0"
```

Arquivo `/etc/xen-tools/role.d/labqs-sshd` para habilitar acesso *SSH* via porta 2222 para usuário *root*

```bash
#!/bin/sh
#
#  This role enable remote SSH access via port 2222
#

prefix=$1

#
#  Source our common functions - this will let us install a Debian package.
#
if [ -e /usr/share/xen-tools/common.sh ]; then
    . /usr/share/xen-tools/common.sh
else
    echo "Installation problem"
fi

#
# Log our start
#
logMessage Script $0 starting

#
# Enable SSH access on port 2222 using password
#
sed -i 's/^#Port\s.*$/Port 2222/' ${prefix}/etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin\s.*$/PermitRootLogin yes/' ${prefix}/etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication\s.*$/PasswordAuthentication yes/' ${prefix}/etc/ssh/sshd_config

#
#  Log our finish
#
logMessage Script $0 finished
```


## Criar VMs

A máquina virtual deve usar o prefixo assinalado pelo servidor *DHCP* para receber corretamente um endereço de rede.

```bash
sudo xen-create-image \
	--hostname='labqs-c1' \
	--memory=1gb \
	--vcpus=2 \
	--lvm=ubuntu-vg  \
    --size=5Gb \
	--nodhcp \
    --gateway=172.16.0.1 \
    --ip=172.16.100.1 \
	--randommac \
    --bridge=xenbr0 \
    --role=labqs-sshd \
	--pygrub \
	--dist=bionic \
    --password=p4ssw0rd \
    --verbose
```


### Extender o volume lógico

```bash
sudo lvextend --size +1G /dev/ubuntu-vg/c1-disk
```


### Iniciar VM

```bash
sudo xl create /etc/xen/labqs-c1.cfg
```

### Acessar a VM

```bash
ssh root@labqs-c1
```

### Recriar VM

```bash
sudo xl destroy labqs-c1
sudo xl create /etc/xen/labqs-c1.cfg
```

## TODO

1. Configurar a comunicação entre a VM e o host para permitir acesso à internet
