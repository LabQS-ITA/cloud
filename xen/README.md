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

```ini
GRUB_CMDLINE_XEN_DEFAULT="dom0_mem=10794M,max:10794M,max_loops=255"
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
net.ipv4.ip_forward=1
```

Atualizar com o comando

```bash
sysctl net.ipv4.ip_forward
```

Adicionar *NAT* _forwarding_

```bash
sudo iptables -t nat -A POSTROUTING -o enp2s0 -j MASQUERADE
sudo dpkg-reconfigure iptables-persistent
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

listen-address=127.0.0.1

domain=labqs.ita.br

cache-size=1000

dhcp-range=10.0.0.100,10.0.0.254,255.0.0.0
dhcp-no-override
dhcp-authoritative
dhcp-lease-max=253
```

Arquivo `/etc/netplan/00-default.yaml` define os endereços fixos das duas interfaces de rede, sendo que uma delas é associada à _bridge_ ligada ao _hypervisor_.

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp2s0f0:
      dhcp4: no
      addresses:
      - 161.24.23.103/24
      routes:
      - to: default
        via: 161.24.23.1
      nameservers:
        addresses:
        - 161.24.23.180
        - 161.24.23.199
        search:
        - labqs.ita.br
        - ita.br

    enp2s0f1:
      dhcp4: no

  bridges:
    xenbr0:
      dhcp4: no
      addresses:
      - 10.0.0.1/8
      routes:
      - to: 10.0.0.0/8
        via: 161.24.23.1
        on-link: true
      interfaces:
      - enp2s0f1
```

Arquivo `/etc/xen/xl.conf` associa a ponte a ser utilizada pelo _hypervisor_.

```ini
vif.default.bridge="xenbr0"
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
sed -i 's/^PasswordAuthentication\s.*$/PasswordAuthentication Yes/' ${prefix}/etc/ssh/sshd_config

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
	--memory=2gb \
	--vcpus=2 \
	--lvm=ubuntu-vg  \
    --size=5Gb \
	--dhcp \
	--randommac \
    --bridge=xenbr0 \
    --gateway=10.0.0.1 \
	--pygrub \
	--dist=bionic \
    --accounts
```


### Extender o volume lógico

```bash
# sudo lvextend -l +10%FREE /dev/ubuntu-vg/c1-disk
```


### Iniciar VM

```bash
sudo xl create /etc/xen/labqs-c1.cfg
```

### Consultar IP

#### Com ISC-DHCP

```bash
dhcp-lease-list
```

#### Com DNSMASQ

```bash
sudo cat /var/lib/misc/dnsmasq.leases
```

### Configuração inicial da VM

```bash
sudo xl console labqs-c1.cfg
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
1. Definir usuário inicial da VM