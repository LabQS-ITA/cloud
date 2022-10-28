#!/usr/bin/env bash
set -euo pipefail

sudo xen-create-image \
	--hostname='labqs-vm-c1' \
	--memory=2gb \
	--vcpus=2 \
	--lvm=ubuntu-vg  \
	--dhcp \
	--randommac \
	--pygrub \
	--dist=bionic