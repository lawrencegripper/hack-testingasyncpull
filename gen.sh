#!/bin/bash
set -e
set -x

# Push 200mb image
dd if=/dev/urandom of=./file.bin  bs=1M count=200
docker build -t lawrencegripper/big:200mb .
docker push lawrencegripper/big:200mb
rm ./file.bin

# Push 600mb image
dd if=/dev/urandom of=./file.bin  bs=1M count=600
docker build -t lawrencegripper/big:600mb .
docker push lawrencegripper/big:600mb
rm ./file.bin

# Push 1000mb image
dd if=/dev/urandom of=./file.bin  bs=1M count=1000
docker build -t lawrencegripper/big:1000mb .
docker push lawrencegripper/big:1000mb
rm ./file.bin

# Push 2000mb image
dd if=/dev/urandom of=./file.bin  bs=1M count=2000
docker build -t lawrencegripper/big:2000mb .
docker push lawrencegripper/big:2000mb
rm ./file.bin