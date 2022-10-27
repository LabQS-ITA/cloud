# Xen Project

## Pré instalação Ubuntu

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
sudo apt-get install xen-hypervisor-amd64

sudo reboot
```

### Configurar memória Xen

```bash
sudo vi /etc/default/grub.d/xen.cfg
```
> GRUB_CMDLINE_XEN_DEFAULT="dom0_mem=10794M,max:10794M,max_loops=255"

```bash
sudo update-grub

sudo reboot
```

### Xen-Tools

```bash
sudo apt install -y xen-tools
```

### Configurar redes

```bash
sudo vi /etc/netplan/00-installer-config.yaml
```

```yaml
# This is the network config written by 'subiquity'
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
      addresses:
      - 192.168.0.1/16
      routes:
      - to: 192.168.0.0/16
        via: 192.168.0.1
        table: 192
    enp2s0f2:
      dhcp4: no
      addresses:
      - 172.16.0.1/12
      routes:
      - to: 172.16.0.0/12
        via: 172.16.0.1
        table: 172
    enp2s0f3:
      dhcp4: no
      addresses:
      - 10.0.0.1/8
      routes:
      - to: 10.0.0.0/8
        via: 10.0.0.1
        table: 10
  bridges:
    xenbr192:
      dhcp4: no
      addresses:
      - 192.168.0.2/16
      routes:
      - to: 192.168.0.0/16
        via: 192.168.0.1
        table: 192
      routing-policy:
      - from: 192.168.0.0/16
        table: 192
      nameservers:
        addresses:
        - 161.24.23.180
        - 161.24.23.199
        search:
        - lan
        - labqs.ita.br
        - ita.br
    xenbr172:
      dhcp4: no
      addresses:
      - 172.16.0.2/12
      routes:
      - to: 172.16.0.0/12
        via: 172.16.0.1
        table: 172
      routing-policy:
      - from: 172.16.0.0/12
        table: 172
      nameservers:
        addresses:
        - 161.24.23.180
        - 161.24.23.199
        search:
        - lan
        - labqs.ita.br
        - ita.br
    xenbr10:
      dhcp4: no
      addresses:
      - 10.0.0.2/8
      routes:
      - to: 10.0.0.0/8
        via: 10.0.0.1
        table: 10
      routing-policy:
      - from: 10.0.0.0/8
        table: 10
      nameservers:
        addresses:
        - 161.24.23.180
        - 161.24.23.199
        search:
        - lan
        - labqs.ita.br
        - ita.br
```

sudo netplan apply --debug


### Serviço DHCP

```bash
sudo apt -y install isc-dhcp-server
sudo vi /etc/default/isc-dhcp-server
```
```ini
# Defaults for isc-dhcp-server (sourced by /etc/init.d/isc-dhcp-server)

# Path to dhcpd's config file (default: /etc/dhcp/dhcpd.conf).
DHCPDv4_CONF=/etc/dhcp/dhcpd.conf
#DHCPDv6_CONF=/etc/dhcp/dhcpd6.conf

# Path to dhcpd's PID file (default: /var/run/dhcpd.pid).
#DHCPDv4_PID=/var/run/dhcpd.pid
#DHCPDv6_PID=/var/run/dhcpd6.pid

# Additional options to start dhcpd with.
#       Don't use options -cf or -pf here; use DHCPD_CONF/ DHCPD_PID instead
#OPTIONS=""

# On what interfaces should the DHCP server (dhcpd) serve DHCP requests?
#       Separate multiple interfaces with spaces, e.g. "eth0 eth1".
INTERFACESv4="enp2s0f1"
#INTERFACESv6=""
```

```bash
sudo vi /etc/dhcp/dhcpd.conf
```
```conf
option domain-name "labqs.ita.br";
option domain-name-servers 161.24.23.180, 161.24.23.199; #ns1.example.org, ns2.example.org;

. . . 

subnet 192.168.0.0 netmask 255.255.0.0 {
        authoritative;
        range 192.168.0.100 192.168.254.254;
        option routers 192.168.0.1;
        deny members of "MSFT 5.0";
}

subnet 172.16.0.0 netmask 255.240.0.0 {
        authoritative;
        range 172.16.0.100 172.31.254.254;
        option routers 172.16.0.1;
        deny members of "MSFT 5.0";
}

subnet 10.0.0.0 netmask 255.0.0.0 {
        authoritative;
        range 10.254.254.100 10.254.254.254;
        option routers 10.0.0.1;
        deny members of "MSFT 5.0";
}
```

```bash
sudo systemctl restart isc-dhcp-server
```


### Criar bridge

```bash
sudo vi /etc/netplan/00-installer-config.yaml
```

```yaml
network:
  ethernets:
    enp2s0f0:
      dhcp4: no
    enp2s0f1:
      dhcp4: true
  bridges:
    xenbr0:
      dhcp4: no
      addresses:
      - AAA.BBB.CCC.DDD/24
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
      interfaces:
      - enp2s0f0
  version: 2
```

```bash
sudo netplan apply
sudo systemctl restart systemd-networkd
```

### Associar bridge com Xen

```bash
sudo vi /etc/xen/xl.conf
```
```ini
vif.default.bridge="xenbr192"
```


## Criar VM

```bash
sudo xen-create-image \
	--hostname=c1 \
	--memory=2gb \
	--vcpus=2 \
	--lvm=ubuntu-vg  \
	--dhcp \
	--randommac \
	--pygrub \
	--dist=bionic
```


### Extender o volume lógico

```bash
# sudo lvextend -l +10%FREE /dev/ubuntu-vg/c1-disk
```


### Iniciar VM

```bash
sudo xl create /etc/xen/c1.cfg
```

sudo xl console c1

passwd p4ssw0rd

vi /etc/network/interfaces

#iface eth0 inet dhcp
iface eth0 inet static
        address AAA.BBB.CCC.DDD
	network 161.24.23.0
        netmask 255.255.255.0
	broadcast 161.24.23.255
        gateway 161.24.23.1

systemctl restart networking

vi /etc/ssh/sshd_config

PermitRootLogin yes
PasswordAuthentication yes

~.


ssh root@AAA.BBB.CCC.DDD


vi /etc/systemd/resolved.conf

DNS=161.24.23.180 161.24.23.199

ip route add default via 161.24.23.1 dev eth0

systemctl restart systemd-resolved

apt-get update -y && apt-get upgrade -y


Configurar VM

sudo xl console c1

sudo dpkg-reconfigure tzdata
echo "America/Sao_Paulo" > /etc/timezone

vi /etc/netplan/00-default.yaml

network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
    dhcp4: no
    addresses: [AAA.BBB.CCC.DDD/24]
    routes:
    - to: default
      via: 161.24.23.1
    nameservers:
      addresses: [161.24.23.180,161.24.23.199]

systemctl restart systemd-networkd # 18.04
systemctl restart networking       # 20.04

/usr/bin/ssh-keygen -A
systemctl enable ssh.service
systemctl start ssh.service

vi /etc/ssh/sshd_config

PermitRootLogin yes
PasswordAuthentication yes

sudo systemctl restart ssh

exit
