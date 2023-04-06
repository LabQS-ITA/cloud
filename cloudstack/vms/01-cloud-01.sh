#!/usr/bin/env bash
set -euo pipefail

nohup sudo xen-create-image \
    --hostname='cloud01.labqs.ita.br' \
    --memory=2Gb \
    --vcpus=2 \
    --dir=/volumes \
    --size=100Gb \
    --ip=172.31.100.1 \
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
    --verbose &
