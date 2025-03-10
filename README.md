
Yocto build for confidential virtual machine images running `entropy-tss` based on [flashbots/yocto-manifests](https://github.com/flashbots/yocto-manifests).

This uses the [meta-entropy-tss](https://github.com/entropyxyz/meta-entropy-tss) layer which has the recipe for adding [`entropy-tss`](https://github.com/entropyxyz/entropy-core/tree/master/crates/threshold-signature-server).

## To build with docker:

- Ensure docker and GNU make are installed, and that docker is running
- `make image-base` 

## To build without docker:

- [Install dependencies](https://github.com/flashbots/yocto-manifests/tree/main#preparing-your-host-for-non-docker-builds), most of which are fairly standard (python, gcc, GNU make, etc), but notably you need [repo](https://gerrit.googlesource.com/git-repo/+/HEAD/README.md).

```
mkdir entropy-tss-image-build && cd entropy-tss-image-build
repo init -u https://github.com/entropyxyz/yocto-build.git -b main -m tdx-base.xml
repo sync
source setup
cd ../..
DEBUG_TWEAKS_ENABLED=1 make build
```

## To deploy to Google Cloud Platform:

There is a script included to do this: [./gcp-deploy](./gcp-deploy) which expects the first argument to be a name identifying the build, which is added as a suffix to the VM instance, and the second argument, which is optional, to be the path to the image file (defaults to an image built with this repo, assuming you run the script from the root of the repo).

Here is an explanation of what the script does:

### Copy the build image to a GCP bucket:

```
gcloud storage buckets create gs://tss-cvm-images
gcloud storage cp srcs/poky/build/tmp/deploy/images/tdx-gcp/core-image-minimal-tdx-gcp.rootfs.wic.tar.gz gs://tss-cvm-images
```

### Create a GCP image from the image file:

```
gcloud compute images create core-image-minimal-tdx-gcp-3 --source-uri gs://cvm-images-flashbots/core-image-minimal-tdx-gcp.rootfs.wic.tar.gz --guest-os-features=UEFI_COMPATIBLE,VIRTIO_SCSI_MULTIQUEUE,GVNIC,TDX_CAPABLE
```

### Setup a GCP firewall rule to allow traffic to port 3001

```
$ gcloud compute firewall-rules create allow-port-3001 \
  --allow tcp:3001 \
  --target-tags entropy-tss \
  --description "Allow traffic on port 3001" \
  --direction INGRESS \
  --priority 1000 \
  --network default
```

### Start a GCP instance using the image:

```
gcloud compute instances create core-image-minimal-tdx-gcp-3 --network=default --confidential-compute-type=TDX --machine-type=c3-standard-4 --maintenance-policy=TERMINATE --image core-image-minimal-tdx-gcp-3 --zone=europe-west4-b --metadata serial-port-enable=TRUE --tags entropy-tss
```
