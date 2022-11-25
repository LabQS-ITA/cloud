

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
