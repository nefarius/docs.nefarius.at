# Windows 11 Gaming VM with GPU pass-thru

WIP

## Prerequisites

### Used Hardware

Part | Usage | Description
---|---|---
Mainboard | Host | [ASUS ROG Crosshair VIII Hero](https://rog.asus.com/us/motherboards/rog-crosshair/rog-crosshair-viii-hero-model/)
CPU | Host, VM | AMD Ryzen 7 3700X 8-Core Processor
GPU #1 | VM | [AMD Radeon RX 6900 XT (16 GB)](https://www.techpowerup.com/gpu-specs/amd-radeon-rx-6900-xt.b10943)
GPU #2 | Host | [AMD Radeon RX 480 (8 GB)](https://www.techpowerup.com/gpu-specs/radeon-rx-480.c2848)
PCIe USB Card | VM | VIA VL805/VL806/VL80x Super Speed USB 3.0 Host Controller

### Used Software

Property | Value
---|---
Date | August 2024
Kernel | 5.15.0-119-generic
Distribution | Linux Mint 21.3 Virginia
QEMU | QEMU emulator version 6.2.0 (Debian 1:6.2+dfsg-2ubuntu6.22)
libvirt | libvirtd (libvirt) 8.0.0
virt-manager | 4.0.0

## Resources

- <https://dannyvanheumen.nl/post/setting-scaling-governor-through-udev-rules/>
- [Sharing files with Virtiofs](https://libvirt.org/kbase/virtiofs.html)
- [How to install virtiofs drivers on Windows](https://virtio-fs.gitlab.io/howto-windows.html)
- [WinFsp](https://winfsp.dev/rel/)
- [Configuring static Hugepages for virtual machine usage](https://mathiashueber.com/configuring-hugepages-use-virtual-machine/)
- [Sharing files with Virtiofs](https://libvirt.org/kbase/virtiofs.html)
- [KVM - Using Hugepages](https://help.ubuntu.com/community/KVM%20-%20Using%20Hugepages)
- [Comprehensive guide to performance optimizations for gaming on virtual machines with KVM/QEMU and PCI passthrough](https://mathiashueber.com/performance-tweaks-gaming-on-virtual-machines/)
- [Improving the performance of a Windows Guest on KVM/QEMU](https://leduccc.medium.com/improving-the-performance-of-a-windows-10-guest-on-qemu-a5b3f54d9cf5)
- [Nested Virtualization - Hyper-V 2019 in qemu-kvm](https://www.redpill-linpro.com/techblog/2021/04/07/nested-virtualization-hyper-v-in-qemu-kvm.html)

## IOMMU Groups

Script: <https://gist.github.com/r15ch13/ba2d738985fce8990a4e9f32d07c6ada>

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
USB:		[0b05:18f3]		 Bus 001 Device 008                       ASUSTek Computer, Inc. AURA LED Controller 
USB:		[05e3:0610]		 Bus 001 Device 007                       Genesys Logic, Inc. Hub 
USB:		[046d:c547]		 Bus 001 Device 005                       Logitech, Inc. USB Receiver 
USB:		[08bb:29c0]		 Bus 001 Device 003                       Texas Instruments PCM2900C Audio CODEC 
USB:		[1038:1294]		 Bus 001 Device 006                       SteelSeries ApS Arctis Pro Wireless 
USB:		[1038:1290]		 Bus 001 Device 004                       SteelSeries ApS Arctis Pro Wireless 
USB:		[0451:2036]		 Bus 001 Device 002                       Texas Instruments, Inc. TUSB2036 Hub 
USB:		[1d6b:0002]		 Bus 001 Device 001                       Linux Foundation 2.0 root hub 
USB:		[1d6b:0003]		 Bus 002 Device 001                       Linux Foundation 3.0 root hub 
		[1022:149c] [R] 06:00.3  USB controller                           Matisse USB 3.0 Host Controller
USB:		[046a:0001]		 Bus 003 Device 003                       Cherry GmbH Keyboard 
USB:		[046d:c33f]		 Bus 003 Device 005                       Logitech, Inc. G815 Mechanical Keyboard 
USB:		[05e3:0610]		 Bus 003 Device 004                       Genesys Logic, Inc. Hub 
USB:		[174c:2074]		 Bus 003 Device 002                       ASMedia Technology Inc. ASM1074 High-Speed hub 
USB:		[1d6b:0002]		 Bus 003 Device 001                       Linux Foundation 2.0 root hub 
USB:		[04c5:2028]		 Bus 004 Device 003                       Fujitsu, Ltd iodd_ST400 
USB:		[05e3:0626]		 Bus 004 Device 004                       Genesys Logic, Inc. USB3.1 Hub 
USB:		[174c:3074]		 Bus 004 Device 002                       ASMedia Technology Inc. ASM1074 SuperSpeed hub 
USB:		[1d6b:0003]		 Bus 004 Device 001                       Linux Foundation 3.0 root hub 
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
USB:		[2516:014d]		 Bus 005 Device 002                       Cooler Master Co., Ltd. ARES 
USB:		[1d6b:0002]		 Bus 005 Device 001                       Linux Foundation 2.0 root hub 
USB:		[1d6b:0003]		 Bus 006 Device 001                       Linux Foundation 3.0 root hub 
Group 29:	[1002:73a4]     0b:00.3  Serial bus controller                    Navi 21 USB
Group 30:	[1002:67df] [R] 0c:00.0  VGA compatible controller                Ellesmere [Radeon RX 470/480/570/570X/580/580X/590]
		[1002:aaf0]     0c:00.1  Audio device                             Ellesmere HDMI Audio [Radeon RX 470/480 / 570/580/590]
Group 31:	[1022:148a] [R] 0d:00.0  Non-Essential Instrumentation [1300]     Starship/Matisse PCIe Dummy Function
Group 32:	[1022:1485] [R] 0e:00.0  Non-Essential Instrumentation [1300]     Starship/Matisse Reserved SPP
Group 33:	[1022:1486] [R] 0e:00.1  Encryption controller                    Starship/Matisse Cryptographic Coprocessor PSPCPP
Group 34:	[1022:149c] [R] 0e:00.3  USB controller                           Matisse USB 3.0 Host Controller
USB:		[0a12:0001]		 Bus 007 Device 006                       Cambridge Silicon Radio, Ltd Bluetooth Dongle (HCI mode) 
USB:		[05e3:0608]		 Bus 007 Device 005                       Genesys Logic, Inc. Hub 
USB:		[046d:082d]		 Bus 007 Device 003                       Logitech, Inc. HD Pro Webcam C920 
USB:		[1d6b:0002]		 Bus 007 Device 001                       Linux Foundation 2.0 root hub 
USB:		[1d6b:0003]		 Bus 008 Device 001                       Linux Foundation 3.0 root hub 
Group 35:	[1022:1487]     0e:00.4  Audio device                             Starship/Matisse HD Audio Controller
```

### VGA PCI IOMMU

```text
/sys/kernel/iommu_groups/26/devices/0000:0b:00.0
/sys/kernel/iommu_groups/27/devices/0000:0b:00.1
/sys/kernel/iommu_groups/28/devices/0000:0b:00.2

0b:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 21 [Radeon RX 6800/6800 XT / 6900 XT] [1002:73bf] (rev c0)
0b:00.1 Audio device [0403]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 21 HDMI Audio [Radeon RX 6800/6800 XT / 6900 XT] [1002:ab28]
0b:00.2 USB controller [0c03]: Advanced Micro Devices, Inc. [AMD/ATI] Device [1002:73a6]
0b:00.3 Serial bus controller [0c80]: Advanced Micro Devices, Inc. [AMD/ATI] Navi 21 USB [1002:73a4]
```

```bash
GRUB_CMDLINE_LINUX_DEFAULT="... vfio_pci.ids=1002:73bf,1002:ab28,1002:73a6,1002:73a4 kvm.ignore_msrs=1"
```

### USB PCI IOMMU

#### Front USB

```text
[1022:149c] [R] 06:00.3  USB controller                           Matisse USB 3.0 Host Controller
USB:		[046a:0001]		 Bus 003 Device 003                       Cherry GmbH Keyboard 
USB:		[046d:c33f]		 Bus 003 Device 009                       Logitech, Inc. G815 Mechanical Keyboard 
USB:		[05e3:0610]		 Bus 003 Device 008                       Genesys Logic, Inc. Hub 
USB:		[174c:2074]		 Bus 003 Device 002                       ASMedia Technology Inc. ASM1074 High-Speed hub 
USB:		[1d6b:0002]		 Bus 003 Device 001                       Linux Foundation 2.0 root hub 
USB:		[05e3:0626]		 Bus 004 Device 005                       Genesys Logic, Inc. USB3.1 Hub 
USB:		[174c:3074]		 Bus 004 Device 002                       ASMedia Technology Inc. ASM1074 SuperSpeed hub 
USB:		[1d6b:0003]		 Bus 004 Device 001                       Linux Foundation 3.0 root hub 
``` 

## USB Controllers

### Before

```text
Bus 008 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 007 Device 004: ID 0a12:0001 Cambridge Silicon Radio, Ltd Bluetooth Dongle (HCI mode)
Bus 007 Device 003: ID 05e3:0608 Genesys Logic, Inc. Hub
Bus 007 Device 002: ID 046d:082d Logitech, Inc. HD Pro Webcam C920
Bus 007 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 006 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 005 Device 002: ID 2516:014d Cooler Master Co., Ltd. ARES
Bus 005 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 004 Device 005: ID 05e3:0626 Genesys Logic, Inc. USB3.1 Hub
Bus 004 Device 002: ID 174c:3074 ASMedia Technology Inc. ASM1074 SuperSpeed hub
Bus 004 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 003 Device 003: ID 046a:0001 Cherry GmbH Keyboard
Bus 003 Device 009: ID 046d:c33f Logitech, Inc. G815 Mechanical Keyboard
Bus 003 Device 008: ID 05e3:0610 Genesys Logic, Inc. Hub
Bus 003 Device 002: ID 174c:2074 ASMedia Technology Inc. ASM1074 High-Speed hub
Bus 003 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 008: ID 0b05:18f3 ASUSTek Computer, Inc. AURA LED Controller
Bus 001 Device 007: ID 05e3:0610 Genesys Logic, Inc. Hub
Bus 001 Device 005: ID 046d:c547 Logitech, Inc. USB Receiver
Bus 001 Device 003: ID 08bb:29c0 Texas Instruments PCM2900C Audio CODEC
Bus 001 Device 006: ID 1038:1294 SteelSeries ApS Arctis Pro Wireless
Bus 001 Device 004: ID 1038:1290 SteelSeries ApS Arctis Pro Wireless
Bus 001 Device 002: ID 0451:2036 Texas Instruments, Inc. TUSB2036 Hub
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```

### After

```text
Bus 009 Device 004: ID 0a12:0001 Cambridge Silicon Radio, Ltd Bluetooth Dongle (HCI mode)
Bus 009 Device 003: ID 05e3:0608 Genesys Logic, Inc. Hub
Bus 009 Device 002: ID 046d:082d Logitech, Inc. HD Pro Webcam C920
Bus 009 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 010 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 008 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 007 Device 002: ID 2516:014d Cooler Master Co., Ltd. ARES
Bus 007 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 006 Device 003: ID 05e3:0626 Genesys Logic, Inc. USB3.1 Hub
Bus 006 Device 002: ID 174c:3074 ASMedia Technology Inc. ASM1074 SuperSpeed hub
Bus 006 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 005 Device 004: ID 046d:c33f Logitech, Inc. G815 Mechanical Keyboard
Bus 005 Device 003: ID 05e3:0610 Genesys Logic, Inc. Hub
Bus 005 Device 002: ID 174c:2074 ASMedia Technology Inc. ASM1074 High-Speed hub
Bus 005 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 004 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 003 Device 008: ID 0b05:18f3 ASUSTek Computer, Inc. AURA LED Controller
Bus 003 Device 007: ID 05e3:0610 Genesys Logic, Inc. Hub
Bus 003 Device 005: ID 046d:c547 Logitech, Inc. USB Receiver
Bus 003 Device 003: ID 08bb:29c0 Texas Instruments PCM2900C Audio CODEC
Bus 003 Device 006: ID 1038:1294 SteelSeries ApS Arctis Pro Wireless
Bus 003 Device 004: ID 1038:1290 SteelSeries ApS Arctis Pro Wireless
Bus 003 Device 002: ID 0451:2036 Texas Instruments, Inc. TUSB2036 Hub
Bus 003 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 002: ID 2109:3431 VIA Labs, Inc. Hub
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```

## Performance tuning

### QEMU Configuration

Set fixed amount of cores, topology and pin cores to best die layout; for `AMD Ryzen 7 3700X 8-Core Processor` it is

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
```

and

```xml
  <cpu mode="host-passthrough" check="none" migratable="on">
    <topology sockets="1" dies="1" cores="4" threads="2"/>
    <cache mode="passthrough"/>
    <feature policy="require" name="topoext"/>
  </cpu>
```

This config maps the last 8 cores to the Windows guest.

For hugepages support add or adjust:

```xml
  <memoryBacking>
    <hugepages>
      <page size="2048" unit="KiB"/>
    </hugepages>
    <access mode="shared"/>
  </memoryBacking>
```

### Host configuration

#### Hugepages

```bash
grep Hugepagesize /proc/meminfo
Hugepagesize:       2048 kB
```

So a value of `8192` pages at a page size of 2MB equals **16GB of RAM reserved** for hugepages.

```ini
GRUB_CMDLINE_LINUX_DEFAULT="... hugepages=8192"
```

`/etc/sysctl.conf`

```ini
kernel.shmmax = 17179869184
vm.nr_hugepages = 8192
vm.min_free_kbytes = 112640
vm.hugetlb_shm_group = 1000
```

#### CPU Governor on performance mode

```bash
echo 'KERNEL=="cpu8|cpu9|cpu10|cpu11|cpu12|cpu13|cpu14|cpu15", SUBSYSTEM=="cpu", ACTION=="add", ATTR{cpufreq/scaling_governor}="performance"' | sudo tee /etc/udev/rules.d/90-scaling-governor-performance.rules
# reboot, then confirm changes with
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

#### Isolate CPU cores from scheduler

> Do more testing if this is beneficial or worse for both host and VM performance

```bash
sudo vim /etc/default/grub
```

```bash
GRUB_CMDLINE_LINUX_DEFAULT="... isolcpus=8-15"
```

```bash
sudo update-grub
```

Reboot to activate.

#### IRQL re-balance

`/etc/default/irqbalance`

```ini
IRQBALANCE_BANNED_CPULIST=8-15
```

```bash
sudo systemctl restart irqbalance
```
