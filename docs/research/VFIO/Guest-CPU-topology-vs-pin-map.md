# Guest CPU topology vs pin map

The action in this article has been conducted under the following conditions:

Property | Value
---|---
Date | September 2026
Kernel | 6.8.0-139-generic
Distribution | Linux Mint 22.3
libvirt | 10.0.0

Related: [Windows 11 Gaming VM with GPU pass-thru](./Windows-11-Gaming-VM.md).

## Problem

`<cputune>` says which *host* CPU each vCPU thread runs on. `<cpu><topology>` is what the *guest* OS believes.

Those two must describe the same shape. If they do not, Windows schedules as if some vCPUs were SMT siblings when they are not.

A common first pin on a 16-thread AMD host is:

```xml
<vcpu placement="static" cpuset="8-15">8</vcpu>
```

with one vCPU per host CPU `8` through `15`. On Zen, those numbers are usually the second thread of eight *different* physical cores (`0/8`, `1/9`, …), not four cores with two threads each.

Advertising this to the guest is then wrong:

```xml
<topology sockets="1" dies="1" cores="4" threads="2"/>
```

Windows will treat vCPU 0+1, 2+3, … as siblings. They are not.

## Approach

Keep the host pin list (`8-15` or whatever you already chose). Change only the advertised topology so each vCPU is a full core with one thread:

```xml
<cpu mode="host-passthrough" check="none" migratable="on">
  <topology sockets="1" dies="1" cores="8" threads="1"/>
  <cache mode="passthrough"/>
  <feature policy="require" name="topoext"/>
</cpu>
```

`topoext` stays on so the guest still sees AMD topology extensions. This does not move QEMU threads and does not change hugepages, governors, or slice affinity.

Do **not** switch to `cores="4" threads="2"` unless the pin list is real SMT pairs, for example `4,12,5,13,6,14,7,15` on a 3700X CCD. That is a different layout.

## Apply

The running domain keeps the old topology until the guest is shut down and started again. `virsh define` updates the persistent XML immediately.

```bash
virsh dumpxml --inactive <domain> > /tmp/<domain>.xml
```

Edit the `<topology>` line, then:

```bash
virsh define /tmp/<domain>.xml
```

Confirm:

```bash
virsh dumpxml --inactive <domain> | grep -A4 '<cpu '
```

After the next guest power cycle:

```bash
virsh dumpxml <domain> | grep topology
```

Inside Windows, Task Manager should show 8 cores / 8 logical processors, not 4 cores / 8 logical processors.

## Notes

- Same logical CPU count (8) so this is not a vCPU resize.
- Leave `<vcpupin>` as-is when only fixing the advertised shape.
- `migratable="on"` is unrelated; it can stay.
