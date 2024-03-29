#! /bin/bash
# MIT License
#
# (C) Copyright [2020] Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# Run this on a system with the GCE SDK installed and access to the
# vshasta-cray project to create an iPXE Boot Disk image suitable for
# use creating Virtual Shasta Network Booted Nodes.

project_id=$NODE_IMAGES_BUILDER_DESTINATION_IMAGE_PROJECT_ID
subnetwork=$NODE_IMAGES_BUILDER_SUBNETWORK
zone=$NODE_IMAGES_BUILDER_ZONE

if [ -z "$project_id" ]; then
  read -p "What's the destination project for this build? " project_id
fi
if [ -z "$subnetwork" ]; then
  read -p "What destination project subnetwork would you like to use for this build? " subnetwork
fi
if [ -z "$zone" ]; then
  read -p "What destination project zone would you like to use for this build (should match the subnetwork provided)? " zone
fi

echo "Creating the ipxe-builder VM Instance"
gcloud compute --project=$project_id instances create ipxe-builder\
       --quiet \
       --zone=$zone \
       --machine-type=n1-standard-8 \
       --subnet=$subnetwork \
       --scopes=https://www.googleapis.com/auth/cloud-platform \
       --image-project=debian-cloud \
       --image-family=debian-9 \
       --boot-disk-size=10GB \
       --create-disk=mode=rw,auto-delete=yes,size=1,type=projects/vshasta-cray/zones/us-central1-a/diskTypes/pd-standard,name=ipxe-boot,device-name=ipxe-boot

echo "Waiting for the ipxe-builder VM Instance to be ready..."
while ! gcloud compute --project=$project_id ssh --zone $zone builder@ipxe-builder -- exit; do
    sleep 10
done
echo
echo "Copying 'ipxe-builder.sh' to the VM Instance"
gcloud compute --quiet --project=$project_id scp --zone $zone scripts/ipxe-builder.sh builder@ipxe-builder:/tmp/ipxe-builder.sh
echo "Building the iPXE Image"
gcloud compute --quiet --project=$project_id ssh --zone $zone builder@ipxe-builder -- /tmp/ipxe-builder.sh
echo "Deleting the 'ipxe-builder' VM Instance"
gcloud compute --quiet --project=$project_id instances delete --zone $zone ipxe-builder
echo "Done"
exit 0
