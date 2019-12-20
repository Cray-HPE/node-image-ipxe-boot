# Preparing an iPXE Boot Image for Virtual Shasta

GCE VM Instances can only boot from a disk of some kind -- they cannot
be configured to network boot from scratch.  On Shasta, however,
Compute Nodes (and, possibly others like UANs) boot from a network
boot server using iPXE.  The boot script is supplied by the BSS on a
per-node basis and refers to specific artifacts (usually at least a
`vmlinuz` file, an `initramfs` file and a `squashfs` root file system
file) by URLs served, in Shasta, by an S3 server.  On Virtual Shasta
we want to emulate this network booting and (eventually) allow the BSS
and S3 server to handle providing the boot script and artifacts on a
per network booted node basis.  To do this, we need to convince GCE to
allow us to network boot a VM Instance.

The solution to this has two parts.  The first part is what this
README file is here to help with.  To give the VM Instance a disk to
'boot' from, We create a boot disk image to be used with network
booted nodes on GCE that effectively acts like iPXE enabled firmware
on the VM Instance.  Instead of booting into a full OS, this boot
image boots into an iPXE boot loader.  What is special about this iPXE
boot loader is that it comes pre-configured with an iPXE script that
knows how to chain to another iPXE script that is embedded in the VM
Instance metadata of the Node.  The metadata iPXE script, in turn,
knows how to chain to a boot script that lives on a boot server
(e.g. the BSS).

To run this procedure you must be logged into a system that has access
to Google Cloud and you must have the GCE SDK (i.e. the gcloud
command) installed and configured to give you access to the
`vshasta-cray` project.

To create an iPXE Boot Disk Image, run the following:

```
$ ./ipxe_image_build
```

in this directory.
