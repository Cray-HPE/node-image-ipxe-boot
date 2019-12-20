#! /bin/bash
#
# Run this on a system with the GCE SDK installed and access to the
# vshasta-cray project to create an iPXE Boot Disk image suitable for
# use creating Virtual Shasta Network Booted Nodes.

echo "Creating the ipxe-builder VM Instance"
gcloud compute --project=vshasta-cray instances create ipxe-builder\
       --quiet \
       --zone=us-central1-a \
       --machine-type=n1-standard-1 \
       --subnet=default-network-us-central1 \
       --network-tier=PREMIUM \
       --maintenance-policy=MIGRATE \
       --service-account=1015742806632-compute@developer.gserviceaccount.com \
       --scopes=https://www.googleapis.com/auth/cloud-platform \
       --image=debian-9-stretch-v20191014 \
       --image-project=debian-cloud \
       --boot-disk-size=10GB \
       --boot-disk-type=pd-standard \
       --boot-disk-device-name=ipxe-builder-2 \
       --create-disk=mode=rw,auto-delete=yes,size=1,type=projects/vshasta-cray/zones/us-central1-a/diskTypes/pd-standard,name=ipxe-boot,device-name=ipxe-boot \
       --reservation-affinity=any

echo "Waiting for the ipxe-builder VM Instance to be ready"
while ! gcloud compute --project=vshasta-cray ssh ipxe-builder \
        -- -o ConnectTimeout=10 /bin/true > /dev/null 2>&1; do
    sleep 10
    echo -n .
done
echo
echo "Copying 'ipxe-builder.sh' to the VM Instance"
gcloud compute --project=vshasta-cray scp scripts/ipxe-builder.sh ipxe-builder:
echo "Building the iPXE Image"
gcloud compute --project=vshasta-cray ssh ipxe-builder -- ./ipxe-builder.sh
echo "Deleting the 'ipxe-builder' VM Instance"
gcloud compute --project=vshasta-cray instances delete --quiet ipxe-builder
echo "Done"
exit 0
