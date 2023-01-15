#!/usr/bin/env bash
set -euo pipefail

sudo xen-create-image \
    --hostname='dev.labqs.ita.br' \
    --memory=4gb \
    --vcpus=2 \
    --lvm=ubuntu-vg  \
    --size=100Gb \
    --ip=172.31.100.2 \
    --broadcast=172.31.255.255 \
    --netmask=255.255.0.0 \
    --gateway=172.31.0.1 \
    --nameserver=161.24.23.180 \
    --randommac \
    --bridge=xenbr0 \
    --role=labqs \
    --pygrub \
    --dist=focal \
    --password='c0r0n@' \
    --verbose
