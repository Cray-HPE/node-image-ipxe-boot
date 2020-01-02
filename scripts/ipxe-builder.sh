#! /bin/bash
#
# Script to run on a GCE VM Instance to create an iPXE Boot Disk image
# for use in making Virtual Shasta Network Booted Nodes

project_id=$(curl -s http://metadata.google.internal/computeMetadata/v1/project/project-id -H "Metadata-Flavor: Google")
zone=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/zone -H "Metadata-Flavor: Google" | sed 's:.*/::')

echo "Installing required packages"
sudo apt-get install -y --quiet git make gcc liblzma-dev > install.out 2>&1
if [ $? -ne 0 ]; then
    cat install.out >&2
    exit 1
fi

echo "Cloning iPXE"
git clone http://git.ipxe.org/ipxe.git > clone.out 2>&1
if [ $? -ne 0 ]; then
    cat clone.out >&2
    exit 1
fi
echo "Building iPXE"
cd ipxe/src
make bin/ipxe.usb CONFIG=cloud EMBED=config/cloud/gce.ipxe > build.out 2>&1
if [ $? -ne 0 ]; then
    cat build.out >&2
    exit 1
fi

echo "Copying iPXE image to disk"
if ! sudo dd if=bin/ipxe.usb of=/dev/sdb bs=4096 conv=sparse; then
    exit 1
fi

img_name=vshasta-ipxe-boot-$(date +%s)
echo "Building new Shasta Network Boot Image '${img_name}'"
if ! gcloud compute --project=$project_id images create ${img_name} \
       --family vshasta-ipxe-boot \
       --source-disk-zone=$zone \
       --source-disk=ipxe-boot \
       --force; then
    exit 1
fi
echo "Success"
exit 0
