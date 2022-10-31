#!/usr/bin/env bash
set -euo pipefail

sudo xen-create-image \
	--hostname='labqs-c1' \
	--memory=1gb \
	--vcpus=2 \
	--lvm=ubuntu-vg  \
    --size=5Gb \
	--dhcp \
	--randommac \
    --bridge=xenbr0 \
    --gateway=10.0.0.1 \
    --role=labqs-sshd \
	--pygrub \
	--dist=bionic \
    --password=p4ssw0rd \
    --verbose
