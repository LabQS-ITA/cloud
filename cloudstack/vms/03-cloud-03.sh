#!/usr/bin/env bash
set -euo pipefail

sudo xen-create-image \
    --hostname='cloud03.labqs.ita.br' \
    --memory=8Gb \
    --vcpus=2 \
    --dir=/volumes \
    --size=200Gb \
    --ip=172.31.100.3 \
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
