#!/usr/bin/env bash
set -euo pipefail

# sem netmask
sudo xen-create-image \
	--hostname='c1.labqs.ita.br' \
	--memory=1gb \
	--vcpus=2 \
	--lvm=ubuntu-vg  \
    --size=20Gb \
    --ip=172.31.100.1 \
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
