# Windows 11 Gaming VM with GPU pass-thru

Hardware and the IOMMU dump below were recorded in August 2024. Host software and the domain XML match the same machine as of September 2026.

Property | Value
---|---
Date | September 2026
Kernel | 6.8.0-139-generic
Distribution | Linux Mint 22.3
QEMU | 8.2.2
libvirt | 10.0.0

Related: [Looking Glass B7 with IVSHMEM](./Looking-Glass-B7.md), [Guest CPU topology vs pin map](./Guest-CPU-topology-vs-pin-map.md), [CPU governor for pinned KVM vCPUs](./CPU-governor-for-pinned-vCPUs.md), [Host CPU affinity for pinned VMs](./Host-CPU-affinity-for-pinned-VMs.md), [Raw virtio-blk boot disk](./Raw-virtio-blk-boot-disk.md).

## Hardware

Part | Role | Device
---|---|---
Mainboard | Host | [ASUS ROG Crosshair VIII Hero](https://rog.asus.com/us/motherboards/rog-crosshair/rog-crosshair-viii-hero-model/)
CPU | Host and guest | AMD Ryzen 7 3700X
GPU | Guest (VFIO) | [AMD Radeon RX 6900 XT (16 GB)](https://www.techpowerup.com/gpu-specs/amd-radeon-rx-6900-xt.b10943)
GPU | Host display | [AMD Radeon RX 480 (8 GB)](https://www.techpowerup.com/gpu-specs/radeon-rx-480.c2848)
USB | Guest | VIA VL805/VL806 SuperSpeed USB 3.0 host controller

Two GPUs are required. The host keeps the RX 480. The 6900 XT and its extra functions go to the guest.

## Host kernel

Bind the guest GPU functions to `vfio-pci` and reserve hugepages before QEMU starts. PCI BDFs move if the card changes slot; the IDs do not.

```bash
GRUB_CMDLINE_LINUX_DEFAULT="... vfio_pci.ids=1002:73bf,1002:ab28,1002:73a6,1002:73a4 kvm.ignore_msrs=1 hugepages=8192"
```

`8192` pages of 2 MiB is 16 GiB. Confirm page size with `grep Hugepagesize /proc/meminfo`.

`/etc/sysctl.conf`:

```ini
kernel.shmmax = 17179869184
vm.nr_hugepages = 8192
vm.min_free_kbytes = 112640
vm.hugetlb_shm_group = 1000
```

`hugetlb_shm_group` is the desktop user’s gid so QEMU can use the pool.

## Guest GPU (VFIO)

Navi 21 exposes four functions. Pass all of them. In the 2024 dump they sat at `0b:00.0`–`0b:00.3` (IOMMU groups 26–29):

```text
0b:00.0 VGA compatible controller [1002:73bf]  Navi 21 (RX 6900 XT)
0b:00.1 Audio device             [1002:ab28]  HDMI audio
0b:00.2 USB controller           [1002:73a6]
0b:00.3 Serial bus controller    [1002:73a4]  Navi 21 USB
```

The full group list is in [IOMMU dump](#iommu-dump).

## USB passthrough

A dedicated USB controller goes to the guest so keyboard, mouse, and similar devices do not share the host xHCI. On this board the front-panel Matisse controller (`1022:149c` at `06:00.3`) holds the G815 and a Cherry keyboard.

`lsusb` **before** that controller is unbound (host still sees those devices):

```text
Bus 003 Device 003: ID 046a:0001 Cherry GmbH Keyboard
Bus 003 Device 009: ID 046d:c33f Logitech, Inc. G815 Mechanical Keyboard
```

**After** bind, those buses disappear from the host. Remaining host USB is the rear hub (AURA, headset dongle, Bluetooth, webcam, and the Cooler Master ARES on the 6900 XT’s own USB).

## Domain CPU and memory

Pin the guest to host CPUs `8-15`. Leave `0-7` for the desktop. Those eight host CPUs are not four SMT pairs, so the guest topology is **8 cores / 1 thread**. `cores=4 threads=2` does not match this pin map. See [Guest CPU topology vs pin map](./Guest-CPU-topology-vs-pin-map.md).

A SATA qcow2 system disk should be converted to raw virtio-blk once `viostor` is a Boot-start driver. Recipe: [Raw virtio-blk boot disk](./Raw-virtio-blk-boot-disk.md).

```xml
<vcpu placement="static" cpuset="8-15">8</vcpu>
<iothreads>2</iothreads>
<cputune>
  <vcpupin vcpu="0" cpuset="8"/>
  <vcpupin vcpu="1" cpuset="9"/>
  <vcpupin vcpu="2" cpuset="10"/>
  <vcpupin vcpu="3" cpuset="11"/>
  <vcpupin vcpu="4" cpuset="12"/>
  <vcpupin vcpu="5" cpuset="13"/>
  <vcpupin vcpu="6" cpuset="14"/>
  <vcpupin vcpu="7" cpuset="15"/>
  <emulatorpin cpuset="0-1"/>
  <iothreadpin iothread="1" cpuset="0-1"/>
  <iothreadpin iothread="2" cpuset="2-3"/>
</cputune>

<cpu mode="host-passthrough" check="none" migratable="on">
  <topology sockets="1" dies="1" cores="8" threads="1"/>
  <cache mode="passthrough"/>
  <feature policy="require" name="topoext"/>
</cpu>

<memoryBacking>
  <hugepages>
    <page size="2048" unit="KiB"/>
  </hugepages>
  <access mode="shared"/>
</memoryBacking>
```

`access mode=shared` is required for virtiofs. On Mint 22, rust `virtiofsd` 1.10 cannot share a domain with `/dev/kvmfr0` (`Illegal seek`). Looking Glass on a virtiofs guest must use `/dev/shm` — see [Looking Glass B7](./Looking-Glass-B7.md).

Spice stays for input. Do not add a QXL head when the 6900 XT is the only display.

## Host CPU tuning

Keep host CPUs `8-15` on `performance` so pinned vCPUs can clock up. A udev rule on `ACTION=="add"` is the first step:

```bash
echo 'KERNEL=="cpu8|cpu9|cpu10|cpu11|cpu12|cpu13|cpu14|cpu15", SUBSYSTEM=="cpu", ACTION=="add", ATTR{cpufreq/scaling_governor}="performance"' | sudo tee /etc/udev/rules.d/90-scaling-governor-performance.rules
```

After a Debian / Mint upgrade, `cpufrequtils` may start later and write `ondemand` to every CPU. Confirm with `cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`. If everything is `ondemand`, the udev rule lost the race. Restore `performance` on the pinned CPUs with the oneshot in [CPU governor for pinned KVM vCPUs](./CPU-governor-for-pinned-vCPUs.md).

Keep host IRQs off the guest CPUs:

```ini
# /etc/default/irqbalance
IRQBALANCE_BANNED_CPULIST=8-15
```

```bash
sudo systemctl restart irqbalance
```

`isolcpus=8-15` was tried and not proven better. Leave it off unless you re-test host and guest together. Prefer systemd slice `AllowedCPUs=` so host userspace stays off the guest CPUs without a kernel cmdline change: [Host CPU affinity for pinned VMs](./Host-CPU-affinity-for-pinned-VMs.md).

## Bridge

One way to put the guest on the LAN is a oneshot that builds `br0` on the I211 (`enp5s0`):

```ini
# /lib/systemd/system/qemu-startup.service
[Unit]
Description=Setup qemu network bridging
After=network-online.target

[Service]
Type=oneshot
Restart=on-failure
ExecStart=brctl addbr br0
ExecStart=brctl addif br0 enp5s0
ExecStart=dhclient br0
ExecStart=ip link set br0 up
ExecStart=iptables -I FORWARD -m physdev --physdev-is-bridged -j ACCEPT

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable --now qemu-startup.service
```

The guest NIC is virtio on that bridge.

## Resources

- [Sharing files with virtiofs](https://libvirt.org/kbase/virtiofs.html)
- [Virtiofs on Windows](https://virtio-fs.gitlab.io/howto-windows.html)
- [WinFsp](https://winfsp.dev/rel/)
- [Static hugepages for VMs](https://mathiashueber.com/configuring-hugepages-use-virtual-machine/)
- [KVM hugepages (Ubuntu)](https://help.ubuntu.com/community/KVM%20-%20Using%20Hugepages)
- [Performance tweaks for KVM/QEMU GPU passthrough](https://mathiashueber.com/performance-tweaks-gaming-on-virtual-machines/)
- [Windows guest performance on QEMU](https://leduccc.medium.com/improving-the-performance-of-a-windows-10-guest-on-qemu-a5b3f54d9cf5)
- [CPU governor via udev](https://dannyvanheumen.nl/post/setting-scaling-governor-through-udev-rules/)
- [Bridged networking with libvirt](https://linuxconfig.org/how-to-use-bridged-networking-with-libvirt-and-kvm)
- [Simple QEMU bridging](https://www.spad.uk/posts/really-simple-network-bridging-with-qemu/)
- IOMMU group script: <https://gist.github.com/r15ch13/ba2d738985fce8990a4e9f32d07c6ada>

## IOMMU dump

August 2024. `[R]` means the group has a reset. USB lines are devices on that controller at capture time.

```text
Group 0:	[1022:1482]     00:01.0  Host bridge                              Starship/Matisse PCIe Dummy Host Bridge
Group 1:	[1022:1483] [R] 00:01.1  PCI bridge                               Starship/Matisse GPP Bridge
Group 2:	[1022:1483] [R] 00:01.2  PCI bridge                               Starship/Matisse GPP Bridge
Group 3:	[1022:1482]     00:02.0  Host bridge                              Starship/Matisse PCIe Dummy Host Bridge
Group 4:	[1022:1482]     00:03.0  Host bridge                              Starship/Matisse PCIe Dummy Host Bridge
Group 5:	[1022:1483] [R] 00:03.1  PCI bridge                               Starship/Matisse GPP Bridge
Group 6:	[1022:1483] [R] 00:03.2  PCI bridge                               Starship/Matisse GPP Bridge
Group 7:	[1022:1482]     00:04.0  Host bridge                              Starship/Matisse PCIe Dummy Host Bridge
Group 8:	[1022:1482]     00:05.0  Host bridge                              Starship/Matisse PCIe Dummy Host Bridge
Group 9:	[1022:1482]     00:07.0  Host bridge                              Starship/Matisse PCIe Dummy Host Bridge
Group 10:	[1022:1484] [R] 00:07.1  PCI bridge                               Starship/Matisse Internal PCIe GPP Bridge 0 to bus[E:B]
Group 11:	[1022:1482]     00:08.0  Host bridge                              Starship/Matisse PCIe Dummy Host Bridge
Group 12:	[1022:1484] [R] 00:08.1  PCI bridge                               Starship/Matisse Internal PCIe GPP Bridge 0 to bus[E:B]
Group 13:	[1022:790b]     00:14.0  SMBus                                    FCH SMBus Controller
		[1022:790e]     00:14.3  ISA bridge                               FCH LPC Bridge
Group 14:	[1022:1440]     00:18.0  Host bridge                              Matisse/Vermeer Data Fabric: Device 18h; Function 0
		[1022:1441]     00:18.1  Host bridge                              Matisse/Vermeer Data Fabric: Device 18h; Function 1
		[1022:1442]     00:18.2  Host bridge                              Matisse/Vermeer Data Fabric: Device 18h; Function 2
		[1022:1443]     00:18.3  Host bridge                              Matisse/Vermeer Data Fabric: Device 18h; Function 3
		[1022:1444]     00:18.4  Host bridge                              Matisse/Vermeer Data Fabric: Device 18h; Function 4
		[1022:1445]     00:18.5  Host bridge                              Matisse/Vermeer Data Fabric: Device 18h; Function 5
		[1022:1446]     00:18.6  Host bridge                              Matisse/Vermeer Data Fabric: Device 18h; Function 6
		[1022:1447]     00:18.7  Host bridge                              Matisse/Vermeer Data Fabric: Device 18h; Function 7
Group 15:	[15b7:5030] [R] 01:00.0  Non-Volatile memory controller           Device 5030
Group 16:	[1022:57ad] [R] 02:00.0  PCI bridge                               Matisse Switch Upstream
Group 17:	[1022:57a3] [R] 03:01.0  PCI bridge                               Matisse PCIe GPP Bridge
Group 18:	[1022:57a3] [R] 03:05.0  PCI bridge                               Matisse PCIe GPP Bridge
Group 19:	[1022:57a4] [R] 03:08.0  PCI bridge                               Matisse PCIe GPP Bridge
		[1022:1485] [R] 06:00.0  Non-Essential Instrumentation [1300]     Starship/Matisse Reserved SPP
		[1022:149c]     06:00.1  USB controller                           Matisse USB 3.0 Host Controller
Group 20:	[1022:57a4] [R] 03:09.0  PCI bridge                               Matisse PCIe GPP Bridge
		[1022:7901] [R] 07:00.0  SATA controller                          FCH SATA Controller [AHCI mode]
Group 21:	[1022:57a4] [R] 03:0a.0  PCI bridge                               Matisse PCIe GPP Bridge
		[1022:7901] [R] 08:00.0  SATA controller                          FCH SATA Controller [AHCI mode]
Group 22:	[15b7:5002] [R] 04:00.0  Non-Volatile memory controller           WD Black 2018/SN750 / PC SN720 NVMe SSD
Group 23:	[8086:1539] [R] 05:00.0  Ethernet controller                      I211 Gigabit Network Connection
Group 24:	[1002:1478] [R] 09:00.0  PCI bridge                               Navi 10 XL Upstream Port of PCI Express Switch
Group 25:	[1002:1479] [R] 0a:00.0  PCI bridge                               Navi 10 XL Downstream Port of PCI Express Switch
Group 26:	[1002:73bf] [R] 0b:00.0  VGA compatible controller                Navi 21 [Radeon RX 6800/6800 XT / 6900 XT]
Group 27:	[1002:ab28]     0b:00.1  Audio device                             Navi 21 HDMI Audio [Radeon RX 6800/6800 XT / 6900 XT]
Group 28:	[1002:73a6]     0b:00.2  USB controller                           Device 73a6
Group 29:	[1002:73a4]     0b:00.3  Serial bus controller                    Navi 21 USB
Group 30:	[1002:67df] [R] 0c:00.0  VGA compatible controller                Ellesmere [Radeon RX 470/480/570/570X/580/580X/590]
		[1002:aaf0]     0c:00.1  Audio device                             Ellesmere HDMI Audio [Radeon RX 470/480 / 570/580/590]
Group 31:	[1022:148a] [R] 0d:00.0  Non-Essential Instrumentation [1300]     Starship/Matisse PCIe Dummy Function
Group 32:	[1022:1485] [R] 0e:00.0  Non-Essential Instrumentation [1300]     Starship/Matisse Reserved SPP
Group 33:	[1022:1486] [R] 0e:00.1  Encryption controller                    Starship/Matisse Cryptographic Coprocessor PSPCPP
Group 34:	[1022:149c] [R] 0e:00.3  USB controller                           Matisse USB 3.0 Host Controller
Group 35:	[1022:1487]     0e:00.4  Audio device                             Starship/Matisse HD Audio Controller
```
