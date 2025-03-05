#!/bin/bash

set -e

mkdir -p ~/.ssh
ssh-keyscan github.com >> ~/.ssh/known_hosts
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
git config --global color.ui true

cd /build

# Clone git repos
repo init -u https://github.com/entropyxyz/yocto-build.git -b ${REVISION} -m tdx-base.xml
repo sync

# Download entropy-tss binary
# TODO --header='Authorization: token $GITHUB_TOKEN'
wget -O entropy-tss $ENTROPY_TSS_BINARY_URI

# TODO unzip and get amd64 version

# TODO sha256sum entropy-tss
# then append `SRC_URI[sha256sum] = "$SHA256SUM"` to srcs/poky/meta-entropy-tss/recipes-core/entropy-tss/entropy-tss.bb
#
# Set executable permissions
chmod a+x entropy-tss

# Move file to binary location directory
mv entropy-tss srcs/poky/meta-entropy-tss/recipes-core/entropy-tss/.


source setup || true

make build || true

cp --dereference /build/srcs/poky/build/tmp/deploy/images/tdx-gcp/* /artifacts/.
