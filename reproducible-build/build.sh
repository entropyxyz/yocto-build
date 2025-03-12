#!/bin/bash

set -e

mkdir -p ~/.ssh
ssh-keyscan github.com >> ~/.ssh/known_hosts
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
git config --global color.ui true

cd /build

repo init -u https://github.com/entropyxyz/yocto-build.git -b ${REVISION} -m tdx-base.xml
repo sync

source setup || true

make build

cp --dereference /build/srcs/poky/build/tmp/deploy/images/tdx-gcp/* /artifacts/.
