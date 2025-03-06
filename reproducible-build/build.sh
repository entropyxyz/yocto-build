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

# Download entropy-tss BINARY_FILENAME
if echo $ENTROPY_TSS_BINARY_URI | grep -q 'github.com'; then
    # If its coming from github include our github token
    wget --header='Authorization: token $GITHUB_TOKEN' -O entropy-tss $ENTROPY_TSS_BINARY_URI

    # If its a zip file (from upload-artifact) unzip and get amd64 version
    if file "$file" | grep -q -i 'zip'; then
	unzip entropy-tss
	BINARY_FILENAME=$(find . -type f -name '*_amd64' | head -n 1)

	if [[ -n "$BINARY_FILENAME" ]]; then
	    echo "Renamed $file to new_filename"
	    mv "$BINARY_FILENAME" entropy-tss
	else
	    echo "No file ending with _amd64 found in archive"
	    exit 1
	fi
    fi
else
    wget -O entropy-tss $ENTROPY_TSS_BINARY_URI
fi

# Include the hash of entropy-tss in the bitbake recipe
ENTROPY_TSS_SHA256=$(sha256sum entropy-tss | awk '{print $1}')
echo 'SRC_URI[sha256sum] = "$SHA256SUM"' >> srcs/poky/meta-entropy-tss/recipes-core/entropy-tss/entropy-tss.bb

# Set executable permissions
chmod a+x entropy-tss

# Move file to binary location directory
mv entropy-tss srcs/poky/meta-entropy-tss/recipes-core/entropy-tss/.

source setup || true

make build || true

cp --dereference /build/srcs/poky/build/tmp/deploy/images/tdx-gcp/* /artifacts/.
