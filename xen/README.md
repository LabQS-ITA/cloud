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

#### Configuração serviço DHCP

Arquivo `/etc/default/isc-dhcp-server` ligado à _bridge_ para o _hypervisor_ de máquinas virtuais e a interface de rede física associada à _bridge_ (ver arquivo `/etc/netplan/00-default.yaml`).

```ini
DHCPDv4_CONF=/etc/dhcp/dhcpd.conf
INTERFACESv4="xenbr10 enp2s0f1"
INTERFACESv6=""
```

Arquivo `/etc/dhcp/dhcpd.conf` define um _pool_ de endereços para as máquinas virtuais cujo nome de _host_ iniciem por `labqs-vm`.

```ini
option domain-name "labqs.ita.br";
option domain-name-servers 161.24.23.180, 161.24.23.199; #ns1.example.org, ns2.example.org;

default-lease-time 600;
max-lease-time 7200;

ddns-update-style none;
deny declines;
deny bootp;

class "labqs-vms" {
    match if ( substring( option host-name, 0, 8 ) = "labqs-vm" );
}

subnet 10.0.0.0 netmask 255.0.0.0 {
    authoritative;
    option routers 10.0.0.1;
    pool {
        range 10.0.0.100 10.0.0.254;
        allow members of "labqs-vms";
    }
}
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
    xenbr10:
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
vif.default.bridge="xenbr10"
```

## Criar VM

A máquina virtual deve usar o prefixo assinalado pelo servidor *DHCP* para receber corretamente um endereço de rede.

```bash
sudo xen-create-image \
	--hostname='labqs-vm-c1' \
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
sudo xl create /etc/xen/labqs-vm-c1.cfg
```

### Configuração inicial da VM

```bash
sudo xl console labqs-vm-c1.cfg
```
