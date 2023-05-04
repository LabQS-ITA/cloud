#!/usr/bin/env bash
set -euo pipefail

sudo xen-create-image \
    --hostname='gpes.ita.br' \
    --memory=8Gb \
    --vcpus=2 \
    --dir=/volumes/data01 \
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
    --password='s3cr37' \
    --verbose
