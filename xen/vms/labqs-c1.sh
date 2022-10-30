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
    --bridge=xenbr10 \
    --gateway=161.24.1.1 \
	--pygrub \
	--dist=bionic \
    --accounts
