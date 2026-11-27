# Windows 11 Gaming VM with GPU pass-thru

Property | Value
---|---
Date | November 2026
Kernel | 6.8.0-139-generic
Distribution | Linux Mint 22.3
QEMU | 8.2.2
libvirt | 10.0.0
Guest OS | Windows 11 25H2 (build 26200)

Related: [Looking Glass B7 with IVSHMEM](./Looking-Glass-B7.md), [Guest CPU topology vs pin map](./Guest-CPU-topology-vs-pin-map.md), [CPU governor for pinned KVM vCPUs](./CPU-governor-for-pinned-vCPUs.md), [Host CPU affinity for pinned VMs](./Host-CPU-affinity-for-pinned-VMs.md), [Raw virtio-blk boot disk](./Raw-virtio-blk-boot-disk.md), [Debugging Windows 11 guest stalls](./Windows-11-guest-stalls.md).

## Hardware

Part | Role | Device
---|---|---
Mainboard | Host | [ASUS ROG Crosshair VIII Hero](https://rog.asus.com/us/motherboards/rog-crosshair/rog-crosshair-viii-hero-model/) (BIOS 4805)
CPU | Host and guest | AMD Ryzen 7 3700X (8 cores / 16 threads)
Memory | Host | 64 GiB (24 GiB reserved as static 2 MiB hugepages for the guest)
GPU | Host display | [AMD Radeon RX 6900 XT (16 GB)](https://www.techpowerup.com/gpu-specs/amd-radeon-rx-6900-xt.b10943)
GPU | Guest (VFIO) | [NVIDIA GeForce RTX 2080 SUPER (8 GB)](https://www.techpowerup.com/gpu-specs/geforce-rtx-2080-super.c3365)
Storage | Host OS | WD Black SN850X 2 TB NVMe
Storage | Guest system disk | WD Black SN850X 2 TB NVMe (raw virtio-blk image)
Storage | Guest games disk | Samsung SSD 870 EVO 2 TB (raw virtio-blk block device)
USB | Optional guest passthrough | VIA VL805/VL806 SuperSpeed USB 3.0 host controller

Two GPUs are required. The host keeps the RX 6900 XT. The RTX 2080 SUPER and its extra functions go to the guest.

## Host kernel

Bind the guest GPU functions to `vfio-pci` and reserve hugepages before QEMU starts. PCI BDFs move if the card changes slot; the IDs do not.

```bash
GRUB_CMDLINE_LINUX_DEFAULT="... vfio-pci.ids=10de:1e81,10de:10f8,10de:1ad8,10de:1ad9 kvm.ignore_msrs=1 hugepages=12288 video=efifb:off video=vesafb:off video=simplefb:off"
```

`12288` pages of 2 MiB is 24 GiB. Confirm page size with `grep Hugepagesize /proc/meminfo`. The `video=…fb:off` flags keep the host firmware framebuffer off the NVIDIA card so it is free for VFIO.

Load VFIO early:

```text
# /etc/modules-load.d/vfio.conf
vfio
vfio_pci
vfio_iommu_type1
vfio_virqfd
```

Blacklist host NVIDIA drivers so they never bind the guest GPU. Libvirt `managed="yes"` then attaches `vfio-pci` when the domain starts:

```text
# /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
options nouveau modeset=0
```

```text
# /etc/modprobe.d/blacklist-nvidia.conf
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
blacklist nvidia_uvm
blacklist nvidia-peermem
```

`nvidiafb` stays in the distribution `blacklist-framebuffer.conf`.

`/etc/sysctl.conf`:

```ini
kernel.shmmax = 25769803776
vm.nr_hugepages = 12288
vm.min_free_kbytes = 112640
vm.hugetlb_shm_group = 1000
```

`hugetlb_shm_group` is the desktop user’s gid so QEMU can use the pool.

## Guest GPU (VFIO)

TU104 exposes four functions. They share IOMMU group 32, so pass all of them. On this machine they sit at `0d:00.0`–`0d:00.3`:

```text
0d:00.0 VGA compatible controller [10de:1e81]  TU104 (RTX 2080 SUPER)
0d:00.1 Audio device             [10de:10f8]  HD Audio
0d:00.2 USB controller           [10de:1ad8]  USB 3.1 xHCI
0d:00.3 Serial bus controller    [10de:1ad9]  USB Type-C UCSI
```

The full group list is in [IOMMU dump](#iommu-dump). Looking Glass needs an active display sink on this GPU; this guest uses an HDMI dummy plug. See [Looking Glass B7](./Looking-Glass-B7.md#guest-needs-a-display-sink-amd).

## Input and USB passthrough {#usb-passthrough}

Daily keyboard, mouse, and clipboard go over Looking Glass plus Spice. The domain has a `com.redhat.spice.0` channel and virtio keyboard/mouse (`vioinput` in Windows). That is enough for the Linux desktop to drive the guest; a dedicated PCI USB controller is not attached.

The guest still receives the RTX 2080 SUPER’s own USB-C controller (`0d:00.2` and `0d:00.3`) because those functions live in the same IOMMU group as the GPU.

### Optional: dedicated USB controller passthrough

A whole xHCI controller can still go to the guest so physical keyboard and mouse devices never share the host. Two controllers on this board are in their own resettable groups:

Controller | PCI ID | BDF | IOMMU group
---|---|---|---
VIA VL805/VL806 add-in card | `1106:3483` | `05:00.0` | 24
CPU Matisse USB 3.0 | `1022:149c` | `0f:00.3` | 36

The chipset Matisse controllers at `07:00.1` and `07:00.3` share group 20 with the Starship/Matisse Reserved SPP device, so they are a poor passthrough target.

This host currently leaves both isolated controllers on `xhci_hcd`. Remaining host USB includes the VIA card, the rear Matisse hub (AURA, headset, Bluetooth, Keychron Link), and the Cooler Master ARES plus OBSBOT camera on the 6900 XT’s own USB.

## Domain CPU and memory

Pin the guest to host CPUs `8-15`. Leave `0-7` for the desktop. Those eight host CPUs are not four SMT pairs, so the guest topology is **8 cores / 1 thread**. `cores=4 threads=2` does not match this pin map. See [Guest CPU topology vs pin map](./Guest-CPU-topology-vs-pin-map.md).

Give the guest 24 GiB of hugepage-backed RAM to match `hugepages=12288`. The system disk is raw virtio-blk with `io_uring`; a dedicated SATA SSD is a second virtio-blk disk on IOThread 2. Recipe: [Raw virtio-blk boot disk](./Raw-virtio-blk-boot-disk.md).

```xml
<memory unit="KiB">25165824</memory>
<currentMemory unit="KiB">25165824</currentMemory>
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

Hide KVM from the NVIDIA Windows driver (`Code 43`) and keep the Hyper-V enlightenments Windows 11 expects:

```xml
<features>
  <hyperv mode="custom">
    <relaxed state="on"/>
    <vapic state="on"/>
    <spinlocks state="on" retries="8191"/>
    <vpindex state="on"/>
    <runtime state="on"/>
    <synic state="on"/>
    <stimer state="on">
      <direct state="on"/>
    </stimer>
    <reset state="on"/>
    <vendor_id state="on" value="0123456789ab"/>
    <frequencies state="on"/>
    <reenlightenment state="on"/>
    <tlbflush state="on"/>
    <ipi state="on"/>
    <evmcs state="off"/>
  </hyperv>
  <kvm>
    <hidden state="on"/>
  </kvm>
</features>
```

Windows 11 boots from OVMF (`OVMF_CODE_4M.secboot.fd`) with an emulated TPM 2.0. `secure-boot` is on but `enrolled-keys` is off and the NVRAM template is empty `OVMF_VARS_4M.fd`, so firmware does not enforce signatures and Windows reports Secure Boot as off. Leave that as-is on this guest: regenerating NVRAM would wipe existing EFI variables. A new VM that needs enforcement should set `enrolled-keys` to `yes` and use `OVMF_VARS_4M.ms.fd`. The clock uses local time with a native TSC and Hyper-V clock:

```xml
<os firmware="efi">
  <type arch="x86_64" machine="pc-q35-6.2">hvm</type>
  <firmware>
    <feature enabled="no" name="enrolled-keys"/>
    <feature enabled="yes" name="secure-boot"/>
  </firmware>
  <loader readonly="yes" secure="yes" type="pflash">/usr/share/OVMF/OVMF_CODE_4M.secboot.fd</loader>
  <nvram template="/usr/share/OVMF/OVMF_VARS_4M.fd"/>
</os>

<tpm model="tpm-crb">
  <backend type="emulator" version="2.0"/>
</tpm>

<clock offset="localtime">
  <timer name="rtc" tickpolicy="catchup"/>
  <timer name="pit" tickpolicy="delay"/>
  <timer name="hpet" present="no"/>
  <timer name="hypervclock" present="yes"/>
  <timer name="tsc" present="yes" mode="native"/>
</clock>
```

`access mode=shared` is required for virtiofs. On Mint 22, rust `virtiofsd` 1.10 cannot share a domain with `/dev/kvmfr0` (`Illegal seek`). Looking Glass on a virtiofs guest must use `/dev/shm` — see [Looking Glass B7](./Looking-Glass-B7.md).

Spice stays for input. Do not add a QXL head when the RTX 2080 SUPER is the only display.

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

One way to put the guest on the LAN is a oneshot that builds `br0` on the I211 (`04:d9:f5:60:f0:0a`). Adding the VIA USB card renamed that NIC from `enp5s0` to `enp6s0`, so the unit selects the NIC by MAC instead of interface name. `addbr`/`addif` are ignored when `br0` or the membership already exists, so a failed run can restart without deleting the bridge first:

```ini
# /lib/systemd/system/qemu-startup.service
[Unit]
Description=Setup qemu network bridging
After=network-online.target

[Service]
Type=oneshot
Restart=on-failure
ExecStart=/bin/sh -c 'brctl addbr br0 || true'
ExecStart=/bin/sh -c 'nic=$(ip -o link | awk -F": " "/04:d9:f5:60:f0:0a/{print \\$2; exit}"); brctl addif br0 "$nic" || true'
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

November 2026. `[R]` means the group has a reset.

```text
Group 0:	[1022:1482]     00:01.0  Host bridge                            Starship/Matisse PCIe Dummy Host Bridge
Group 1:	[1022:1483] [R] 00:01.1  PCI bridge                             Starship/Matisse GPP Bridge
Group 2:	[1022:1483] [R] 00:01.2  PCI bridge                             Starship/Matisse GPP Bridge
Group 3:	[1022:1482]     00:02.0  Host bridge                            Starship/Matisse PCIe Dummy Host Bridge
Group 4:	[1022:1482]     00:03.0  Host bridge                            Starship/Matisse PCIe Dummy Host Bridge
Group 5:	[1022:1483] [R] 00:03.1  PCI bridge                             Starship/Matisse GPP Bridge
Group 6:	[1022:1483] [R] 00:03.2  PCI bridge                             Starship/Matisse GPP Bridge
Group 7:	[1022:1482]     00:04.0  Host bridge                            Starship/Matisse PCIe Dummy Host Bridge
Group 8:	[1022:1482]     00:05.0  Host bridge                            Starship/Matisse PCIe Dummy Host Bridge
Group 9:	[1022:1482]     00:07.0  Host bridge                            Starship/Matisse PCIe Dummy Host Bridge
Group 10:	[1022:1484] [R] 00:07.1  PCI bridge                             Starship/Matisse Internal PCIe GPP Bridge 0 to bus[E:B]
Group 11:	[1022:1482]     00:08.0  Host bridge                            Starship/Matisse PCIe Dummy Host Bridge
Group 12:	[1022:1484] [R] 00:08.1  PCI bridge                             Starship/Matisse Internal PCIe GPP Bridge 0 to bus[E:B]
Group 13:	[1022:790b]     00:14.0  SMBus                                  FCH SMBus Controller
		[1022:790e]     00:14.3  ISA bridge                             FCH LPC Bridge
Group 14:	[1022:1440]     00:18.0  Host bridge                            Matisse/Vermeer Data Fabric: Device 18h; Function 0
		[1022:1441]     00:18.1  Host bridge                            Matisse/Vermeer Data Fabric: Device 18h; Function 1
		[1022:1442]     00:18.2  Host bridge                            Matisse/Vermeer Data Fabric: Device 18h; Function 2
		[1022:1443]     00:18.3  Host bridge                            Matisse/Vermeer Data Fabric: Device 18h; Function 3
		[1022:1444]     00:18.4  Host bridge                            Matisse/Vermeer Data Fabric: Device 18h; Function 4
		[1022:1445]     00:18.5  Host bridge                            Matisse/Vermeer Data Fabric: Device 18h; Function 5
		[1022:1446]     00:18.6  Host bridge                            Matisse/Vermeer Data Fabric: Device 18h; Function 6
		[1022:1447]     00:18.7  Host bridge                            Matisse/Vermeer Data Fabric: Device 18h; Function 7
Group 15:	[15b7:5030] [R] 01:00.0  Non-Volatile memory controller         WD Black SN850X NVMe SSD
Group 16:	[1022:57ad] [R] 02:00.0  PCI bridge                             Matisse Switch Upstream
Group 17:	[1022:57a3] [R] 03:01.0  PCI bridge                             Matisse PCIe GPP Bridge
Group 18:	[1022:57a3] [R] 03:02.0  PCI bridge                             Matisse PCIe GPP Bridge
Group 19:	[1022:57a3] [R] 03:05.0  PCI bridge                             Matisse PCIe GPP Bridge
Group 20:	[1022:57a4] [R] 03:08.0  PCI bridge                             Matisse PCIe GPP Bridge
		[1022:1485] [R] 07:00.0  Non-Essential Instrumentation          Starship/Matisse Reserved SPP
		[1022:149c]     07:00.1  USB controller                         Matisse USB 3.0 Host Controller
		[1022:149c] [R] 07:00.3  USB controller                         Matisse USB 3.0 Host Controller
Group 21:	[1022:57a4] [R] 03:09.0  PCI bridge                             Matisse PCIe GPP Bridge
		[1022:7901] [R] 08:00.0  SATA controller                        FCH SATA Controller [AHCI mode]
Group 22:	[1022:57a4] [R] 03:0a.0  PCI bridge                             Matisse PCIe GPP Bridge
		[1022:7901] [R] 09:00.0  SATA controller                        FCH SATA Controller [AHCI mode]
Group 23:	[15b7:5030] [R] 04:00.0  Non-Volatile memory controller         WD Black SN850X NVMe SSD
Group 24:	[1106:3483] [R] 05:00.0  USB controller                         VL805/806 xHCI USB 3.0 Controller
Group 25:	[8086:1539] [R] 06:00.0  Ethernet controller                    I211 Gigabit Network Connection
Group 26:	[1002:1478] [R] 0a:00.0  PCI bridge                             Navi 10 XL Upstream Port of PCI Express Switch
Group 27:	[1002:1479] [R] 0b:00.0  PCI bridge                             Navi 10 XL Downstream Port of PCI Express Switch
Group 28:	[1002:73bf] [R] 0c:00.0  VGA compatible controller              Navi 21 [Radeon RX 6800/6800 XT / 6900 XT]
Group 29:	[1002:ab28]     0c:00.1  Audio device                           Navi 21/23 HDMI/DP Audio Controller
Group 30:	[1002:73a6]     0c:00.2  USB controller                         Device 73a6
Group 31:	[1002:73a4]     0c:00.3  Serial bus controller                  Navi 21 USB
Group 32:	[10de:1e81] [R] 0d:00.0  VGA compatible controller              TU104 [GeForce RTX 2080 SUPER]
		[10de:10f8]     0d:00.1  Audio device                           TU104 HD Audio Controller
		[10de:1ad8]     0d:00.2  USB controller                         TU104 USB 3.1 Host Controller
		[10de:1ad9]     0d:00.3  Serial bus controller                  TU104 USB Type-C UCSI Controller
Group 33:	[1022:148a] [R] 0e:00.0  Non-Essential Instrumentation          Starship/Matisse PCIe Dummy Function
Group 34:	[1022:1485] [R] 0f:00.0  Non-Essential Instrumentation          Starship/Matisse Reserved SPP
Group 35:	[1022:1486] [R] 0f:00.1  Encryption controller                  Starship/Matisse Cryptographic Coprocessor PSPCPP
Group 36:	[1022:149c] [R] 0f:00.3  USB controller                         Matisse USB 3.0 Host Controller
Group 37:	[1022:1487]     0f:00.4  Audio device                           Starship/Matisse HD Audio Controller
```
