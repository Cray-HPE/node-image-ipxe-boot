#! /bin/bash
#
# Run this on a system with the GCE SDK installed and access to the
# vshasta-cray project to create an iPXE Boot Disk image suitable for
# use creating Virtual Shasta Network Booted Nodes.

project_id="vshasta-cray"
zone="us-central1-a"

echo "Creating the ipxe-builder VM Instance"
gcloud compute --project=$project_id instances create ipxe-builder\
       --quiet \
       --zone=$zone \
       --machine-type=n1-standard-8 \
       --subnet=default-network-us-central1 \
       --service-account=1015742806632-compute@developer.gserviceaccount.com \
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