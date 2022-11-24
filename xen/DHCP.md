

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
