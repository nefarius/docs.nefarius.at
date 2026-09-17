# Raw virtio-blk boot disk

The action in this article has been conducted under the following conditions:

Property | Value
---|---
Date | September 2026
Kernel | 6.8.0-139-generic
Distribution | Linux Mint 22.3
QEMU | 8.2.2
libvirt | 10.0.0

Related: [Windows 11 Gaming VM with GPU pass-thru](./Windows-11-Gaming-VM.md).

## Problem

A Windows guest installed on emulated SATA (`ide-hd`) with a qcow2 system disk spends a lot of I/O time in QEMU even when the file lives on a fast NVMe. Two leftover iothreads do nothing if no disk references them.

VirtIO block (`viostor`) is the usual driver if the guest already has extra virtio-blk data disks. VirtIO SCSI (`vioscsi`) is a different driver; switching the *boot* disk to SCSI in the same window can fail to boot unless that driver is already a Boot-start device.

## Approach

In one downtime window:

1. Confirm `viostor` is **Boot** and **Running** in the guest (`driverquery` / `pnputil`).
2. Shut the domain down (not reboot).
3. Convert the system qcow2 to raw next to the original. Keep the qcow2 until Windows has booted cleanly.
4. Point the persistent XML at the raw file as virtio-blk with an iothread.

```xml
<disk type="file" device="disk">
  <driver name="qemu" type="raw" cache="none" io="io_uring" discard="unmap" iothread="1"/>
  <source file="/var/lib/libvirt/images/guest-system.raw"/>
  <target dev="vde" bus="virtio"/>
  <boot order="1"/>
</disk>
```

`target dev` must be an unused virtio name. List existing ones before you edit:

```bash
virsh dumpxml --inactive <domain> | grep -E "bus=.virtio"
```

If `vda`–`vdd` are already data disks (or other virtio devices), pick the next free `vdX` (`vde` in the example). Leave those disks and GPU hostdevs unchanged. Omit `<address>` on the new disk so libvirt picks a free PCIe port.

Have BitLocker recovery material reachable. A controller change can demand it.

## Convert

The domain must be **shut off**. Run the convert as root, then give the image back to the qemu user:

```bash
sudo qemu-img convert -p -f qcow2 -O raw \
  /var/lib/libvirt/images/guest-system.qcow2 \
  /var/lib/libvirt/images/guest-system.raw
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/guest-system.raw
sudo chmod 600 /var/lib/libvirt/images/guest-system.raw
sudo qemu-img info /var/lib/libvirt/images/guest-system.raw
```

Need enough free space for the raw file *plus* the qcow2 until you delete the old one.

## Define and start

```bash
virsh dumpxml --inactive <domain> > /tmp/<domain>.xml
cp /tmp/<domain>.xml /tmp/<domain>.rollback.xml
# edit /tmp/<domain>.xml (the system <disk> as above)
virsh define /tmp/<domain>.xml
virsh start <domain>
```

If Windows does not boot on the raw virtio-blk disk, define the rollback XML and start again. The qcow2 is still the boot image in that file:

```bash
virsh destroy <domain>   # only if it is still running
virsh define /tmp/<domain>.rollback.xml
virsh start <domain>
```

Confirm:

```bash
virsh dumpxml <domain> | grep -A8 "device='disk'"
```

The boot disk should show `type='raw'`, `bus='virtio'`, and `iothread='1'`.

Inside Windows, the boot volume should appear as a Red Hat VirtIO disk (`VEN_1AF4&DEV_1042`) with `viostor` still Boot/Running.

## Retire the qcow2

Keep the qcow2 until the guest has completed **two** clean boots. Then rename or delete it. Do not delete it to “free space” on the first attempt.

## Notes

- This is not virtio-scsi. Use SCSI only after `vioscsi` is a Boot-start driver.
- `io='io_uring'` needs a recent QEMU and kernel (8.2 / 6.8 here).
- Reuse the same recipe on other Windows domains that already have `viostor` in use.
