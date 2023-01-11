#!/usr/bin/env bash
set -euo pipefail

sudo xen-create-image \
    --hostname='labqs.ita.br' \
    --memory=8gb \
    --vcpus=2 \
    --lvm=ubuntu-vg  \
    --size=200Gb \
    --ip=161.24.23.136 \
    --netmask=161.24.23.0 \
    --broadcast=161.24.23.255 \
    --netmask=255.255.255.0 \
    --gateway=161.24.23.1 \
    --nameserver=161.24.23.180 \
    --randommac \
    --role=labqs \
    --pygrub \
    --dist=focal \
    --password='c0r0n@' \
    --verbose
