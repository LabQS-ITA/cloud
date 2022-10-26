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

### Criar bridge

```bash
sudo vi /etc/netplan/00-installer-config.yaml
```

```
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

## Criar VM

```bash
sudo xen-create-image \
	--hostname=c1 \
	--memory=2gb \
	--vcpus=2 \
	--lvm=ubuntu-vg  \
	--nodhcp \
	--ip=AAA.BBB.CCC.DDD \
	--broadcast=161.24.23.255 \
	--netmask=255.255.255.0 \
	--gateway=161.24.23.1 \
	--randommac \
	--pygrub \
	--dist=bionic
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
