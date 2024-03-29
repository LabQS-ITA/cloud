# Xen Project

[The Linux Foundation Xen Project](https://xenproject.org)

## Configuração atual

Atualmente servidores discretos possuem containers que isolam as aplicações:

```mermaid
graph TD
    subgraph servidor 1
        subgraph sistema operacional 1
            subgraph containers 1
                postgres1
                app1
                app1
                postgres4
                app7
                app8
                app9
            end
        end
    end
```

<div style="page-break-after: always;"></div>

O crescimento acontece de modo horizontal, adicionando-se mais servidores:

```mermaid
graph TD
    subgraph servidor 1
        subgraph sistema operacional 1
            subgraph containers 1
            end
        end
    end
    subgraph servidor 2
        subgraph sistema operacional 2
            subgraph containers 2
            end
        end
    end
```

<div style="page-break-after: always;"></div>

## Proposta

Utilizando um hipervisor podemos criar ambientes de pesquisa, desenvolvimento, simulações e testes discretos dentro do mesmo servidor

```mermaid
graph TD
    subgraph servidor 3
        subgraph hipervisor 1
            subgraph maquina virtual 1
                subgraph sistema operacional 1
                    subgraph containers 1
                        postgres3
                        app5
                        app6
                    end
                end
            end
            subgraph maquina virtual 2
                subgraph sistema operacional 2
                    subgraph containers 2
                        postgres4
                        app7
                        app8
                        app9
                    end
                end
            end
        end
    end
```

<div style="page-break-after: always;"></div>

Permitindo crescimento horizontal com a adição de servidores, e vertical usando mais a capacidade instalada de cada servidor:

```mermaid
graph TD
    subgraph servidor 3
        subgraph hipervisor 1
            subgraph maquina virtual 1
                subgraph sistema operacional 1
                    subgraph containers 1
                    end
                end
            end
            subgraph maquina virtual 2
                subgraph sistema operacional 2
                    subgraph containers 2
                    end
                end
            end
        end
    end
    subgraph servidor 4
        subgraph hipervisor 2
            subgraph maquina virtual 3
                subgraph sistema operacional 3
                    subgraph containers 3
                    end
                end
            end
            subgraph maquina virtual 4
                subgraph sistema operacional 4
                    subgraph containers 4
                    end
                end
            end
        end
    end 
```

# Configuração do ambiente

## Pré instalação Ubuntu

### Ajustar `hosts`

No arquivo `/etc/hosts`, eliminar linha

```
127.0.1.1 <nome do host>
```

### Atualizar sistema

```sh
sudo apt update && sudo apt upgrade -y
```

<div style="page-break-after: always;"></div>

### Criar usuários

```sh
sudo adduser --disabled-password --gecos "" gpes
sudo usermod --password $(echo c0r0n@ | openssl passwd -1 -stdin) gpes
```

#### Autorizar para sudo

```sh
echo "gpes ALL=(ALL:ALL) ALL" | sudo tee /etc/sudoers.d/gpes
```

## Instalar Xen Hypervisor

```sh
sudo apt-get install -y xen-hypervisor-amd64
sudo reboot
```

### Configurar memória Xen

Inspecionar quanto de memória temos disponível:

```sh
sudo lshw -short -class memory
```

Arquivo `/etc/default/grub.d/xen.cfg`

Opção com 16Gb:

```ini
GRUB_CMDLINE_XEN_DEFAULT="dom0_mem=2048M,max=2048M"
```

```sh
sudo update-grub2
sudo reboot
```

### Xen-Tools

```sh
sudo apt install -y xen-tools
```

<div style="page-break-after: always;"></div>

## Configurar redes

### Gateway interno

Arquivo `/etc/sysctl.conf`, remover o comentário da linha:

```ini
net.ipv4.ip_forward = 1
```

Atualizar com o comando

```sh
sudo sysctl -p
```

Adicionar *NAT* _forwarding_ evitando que **systemd-resolved** entre em conflito com o mapeamento (opção *! -o lo*)

```sh
sudo iptables ! -o lo -t nat -A POSTROUTING -j MASQUERADE
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

<div style="page-break-after: always;"></div>

## Habilitar ssh na Máquina Virtual

Arquivo `/etc/xen-tools/role.d/labqs` para habilitar acesso *SSH* via porta 2222 para usuário *root* (modificar para torná-lo executável):

```sh
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

### Tornar executável

```sh
sudo chmod +x /etc/xen-tools/role.d/labqs
```

<div style="page-break-after: always;"></div>


## Configurar `xen-tools` para instalar Ubuntu 20.04

Editar `/etc/xen-tools/distributions.conf` e adicionar a linha abaixo logo após `bionic`

```ini
focal        = ubuntu     pygrub
```

Criar link para configurar a distribuição

```sh
cd /usr/share/xen-tools
ln -s artful.d focal.d
```

## Criar Máquinas Virtuais

```sh
sudo xen-create-image \
	--hostname='gpes.ita.br' \
	--memory=1gb \
	--vcpus=2 \
	--lvm=ubuntu-vg  \
    --size=20Gb \
    --ip=172.31.100.1 \
    --netmask=172.31.0.0 \
    --broadcast=172.31.255.255 \
    --netmask=255.255.0.0 \
    --gateway=172.31.0.1 \
    --nameserver=161.24.23.180 \
	--randommac \
    --bridge=xenbr0 \
    --role=labqs-sshd \
	--pygrub \
	--dist=bionic \
    --password='c0r0n@' \
    --verbose
```

### Iniciar a Máquina Virtual

```sh
sudo xl create /etc/xen/gpes.ita.br.cfg
```

### Programar para a Máquina Virtual re-iniciar após boot

Editar `/etc/xen/gpes.ita.br.cfg`, localizar e modificar `on_poweroff` para `restart`:

```ini
on_poweroff = 'restart'
on_reboot   = 'restart'
on_crash    = 'restart'
```

Ou opção para ficar em standby

```ini
on_poweroff = 'preserve'
on_reboot   = 'preserve'
on_crash    = 'preserve'
```

### Acessar a Máquina Virtual

```sh
ssh -p 2222 root@172.31.100.1
```

> **OBSERVAÇÃO** - pode ser necessário apagar uma entrada anterior para a máquina virtual no arquivo `~/.ssh/know_hosts` caso ela tenha sido recriada.

<div style="page-break-after: always;"></div>

### Acessar a Máquina Virtual via console

```sh
sudo xl console cloud01.labqs.ita.br
```

### Acessar a máquina virtual externamente

É possível acessar a máquina virtual externamente por meio de uma porta do _host_, porém caso deseje acessar uma porta específica (como a porta **80** para aplicações internet), então a máquina virtual deve ter um endereço **IP** próprio para ser exposta à internet.

No primeiro caso (_acesso às portas **80** e **443** de uma aplicação internet rodando na máquina virtual_), a porta 80 do _host_ poderá ser mapeada diretamente para a máquina virtual:


#### Exemplo de roteamento de porta autorizada para a **DMZ**

Antes instalar `iptables-persistent` para reter as configurações:

```sh
sudo apt install -y iptables-persistent
```

Criar as regras

```sh
sudo iptables -t nat -A PREROUTING -i enp2s0f0 -p tcp -m tcp --dport 60001 -j DNAT --to-destination 172.31.100.1:2222

sudo iptables -t nat -A PREROUTING -i enp2s0f0 -p tcp -m tcp --dport 80 -j DNAT --to-destination 172.31.100.1:80
sudo iptables -t nat -A PREROUTING -i enp2s0f0 -p tcp -m tcp --dport 443 -j DNAT --to-destination 172.31.100.1:443

sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

Reservar as portas `60000 ~ 60099` pelo sistema operacional

```sh
sudo sysctl -w net.ipv4.ip_local_reserved_ports=60000,60099
```

Outro caso é o de mapear dois serviços distintos que utilizam a mesma porta em máquinas virtuais diferentes. Vamos supor que temos dois serviços **Postgres** instalados em duas máquinas virtuais diferentes, e ambos utilizam a mesma porta **5400**. O primeiro poderá usar a porta **5400** do _host_, porém o segundo deverá usar uma porta diferente.

#### Rotear porta para administração de containers

```sh
sudo iptables -t nat -A PREROUTING -i enp2s0f0 -p tcp -m tcp --dport 9001 -j DNAT --to-destination 172.31.100.1:9001

sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

#### Exemplo de roteamento de porta não autorizada para a **DMZ**

Do mesmo modo que a porta autorizada, é preciso criar a rota:

```sh
sudo iptables -t nat -A PREROUTING -i enp2s0f0 -p tcp -m tcp --dport 5400 -j DNAT --to-destination 172.31.100.1:5400
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

Vamos usar como modelo a instalação do **Postgres** no container **Docker**, que está configurado deste modo:

```yaml
    ports:
      - '5400:5432'
```

<div style="page-break-after: always;"></div>

O endereço IP é o definido para a máquina virtual (extraído do _script_ de criação da máquina virtual logo mais acima):

```sh
    --ip=172.31.100.1 \
```

Em seguida podemos acessar o serviço **Postgres** via **VPN** acessando a porta `5400`:

![Dados do host Postgres](./images/01-host-postgres.png)

Devemos também informar uma conexão com o _host_ via túnel _SSH_ com as credenciais da **VPN** (no exemplo abaixo estamos usando um arquivo com chave _pública_/_privada_):

![Tunel SSH](./images/02-tunnel-ssh.png)

<div style="page-break-after: always;"></div>

#### Exemplo de roteamento de porta não autorizada para a **DMZ** para um segundo servidor **Postgres** na mesma porta

Novamente é preciso criar uma rota, só que desta vez mapeada para outra porta no _host_ ao invés de usar a mesma porta da máquina virtual:

```sh
sudo iptables -t nat -A PREROUTING -i enp2s0f0 -p tcp -m tcp --dport 5300 -j DNAT --to-destination 172.31.100.1:5400
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

Os procedimentos para conexão serão os mesmos, só que desta vez utilizando a porta **5300** ao invés da **5400** utilizada no exemplo anterior.

### Excluir regras (caso deseje reverter)

Listar a regra

 ```sh
sudo iptables -L -t nat --line-numbers
 ```

Excluir pelo número da linha

```sh
sudo iptables -t nat -D PREROUTING 1
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```


## Ajustes para executar o ambiente LabQS sem certificados digitais

### Configurar redirect HTTP

Observar que a configuração dos servidores **HTTPD** possuem os seguintes parâmetros:

```xml
<VirtualHost *:80>
  
    ServerName ${LAB_DOMAIN}

    Redirect permanent / https://${LAB_DOMAIN}/

</VirtualHost>
```

A variável `$LAB_DOMAIN` é geralmente iniciada com o domínio registrado no **DNS** para o servidor em questão, o que pode causar um redirect para um dos servidores do **LabQS** caso a configuração dos novos servidores não seja modificada corretamente.


### Recriar a Máquina Virtual

```sh
sudo xl destroy cloud01.labqs.ita.br
sudo xl create /etc/xen/cloud01.labqs.ita.br.cfg
```

### Remover a Máquina Virtual

```sh
sudo xl destroy gpes.ita.br
sudo rm /etc/xen/gpes.ita.br.cfg
sudo lvremove /dev/ubuntu-vg/gpes.ita.br-swap --yes
sudo lvremove /dev/ubuntu-vg/gpes.ita.br-disk --yes
```

Caso o volume acuse que está em uso basta remove-lo da lista do sistema operacional (um dos dois):

```sh
sudo umount /dev/mapper/labqsvg-gpes.ita.br--disk
sudo lvremove /dev/labqsvg/gpes.ita.br-disk --yes
```

## Remover Xen

```sh
sudo apt --yes --purge remove xen*
```

### Outros arquivos

1. volumes criados pelas VMs
1. remover arquivos `/etc/xen*`
1. remover arquivos `/var/lib/xen*`
1. remover configuração GRUB em `/etc/default/grub.d/xen.cfg` e executar `update-grub`



<div style="page-break-after: always;"></div>

# LabQS

```mermaid
journey
    title LabQS
    section Configurações
        Containers para serviços: 5: Me
        Máquinas virtuais para ambientes: 3: Me
        Migrar ambientes: 1: Me
        Divulgar disponibilidade: 1: Me
```

<div style="page-break-after: always;"></div>

# Servidor IA-PLN/Dev

```mermaid
journey
    title LabQS
    section Servidor IA-PLN
        Especificar servidor: 5: Me
        Comprar servidor: 5: Marcos
        Receber servidor: 5: Marcos
        Configurar servidor: 5: Me, Marcos
        Configurar redes: 5: Me, Cássio
        Testar servidor: 5: Me, Wesley, Aline
        Divulgar disponibilidade: 5: Me
```

# Servidor IA-PLN/Ops

```mermaid
journey
    title LabQS
    section Servidor IA-PLN
        Especificar servidor: 3: Me
        Comprar servidor: 1: Marcos
        Receber servidor: 1: Marcos
        Configurar servidor: 1: Me, Marcos
        Configurar redes: 1: Me, Cássio
        Testar servidor: 1: Me, Wesley, Aline
        Divulgar disponibilidade: 1: Me
```

<div style="page-break-after: always;"></div>

# Servidor ES-TIH/Storage

```mermaid
journey
    title LabQS
    section Servidor ES-TIH
        Especificar servidor: 3: Me, Marcos
        Comprar servidor: 1: Marcos
        Receber servidor: 1: Marcos
        Configurar servidor: 1: Me, Marcos
        Configurar redes: 1: Me, Cássio
        Testar servidor: 1: Me, Henrique
        Divulgar disponibilidade: 1: Me
```

# Servidor ES-TIH/Processing

```mermaid
journey
    title LabQS
    section Servidor ES-TIH
        Especificar servidor: 1: Me, Marcos
        Comprar servidor: 1: Marcos
        Receber servidor: 1: Marcos
        Configurar servidor: 1: Me, Marcos
        Configurar redes: 1: Me, Cássio
        Testar servidor: 1: Me, Henrique
        Divulgar disponibilidade: 1: Me
```

# Desinstalar o Hypervisor

```sh
sudo apt remove --yes xen*
sudo apt remove --yes qemu*
sudo mv /etc/default/grup.d/xen.cfg /etc/default/grup.d/xen.cfg_old
sudo reboot
```