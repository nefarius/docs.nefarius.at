# Research area

Hello! 👋

This is a general-purpose section where mixed content ends up that doesn't really fall into a specific category. Think of it as a very chaotic wiki/knowledge-base for stuff you probably never need 😁

## Cameras

- [Bedee 2 MP IP camera: hardware, firmware backup and OpenIPC](Bedee-IP-Camera-OpenIPC.md) — UART recovery, a verified flash backup, OpenIPC installation, and restoring automatic infrared day/night operation.

## Displays and window placement

- [ASUS PG278Q Monitor on Linux](ASUS-PG278Q-Monitor-on-Linux.md) — Supply a custom EDID so Linux recognizes the monitor's native modes instead of falling back to 640×480.
- [Force specific X11 windows onto the primary monitor](Force-X11-windows-onto-the-primary-monitor.md) — Move the Vesktop splash screen and Git Credential Manager dialogs onto the RandR primary output.

## Virtual machines (VFIO)

- [Windows 11 Gaming VM with GPU pass-thru](VFIO/Windows-11-Gaming-VM.md) — Pass an AMD Radeon RX 6900 XT and a USB controller through to a Windows 11 gaming guest.
- [Looking Glass B7 with IVSHMEM](VFIO/Looking-Glass-B7.md) — Show the passed-through guest framebuffer on the Linux desktop through Looking Glass, IVSHMEM sizing, and the Mesa 25 EGL FSR1 shader fix.
- [Guest CPU topology vs pin map](VFIO/Guest-CPU-topology-vs-pin-map.md) — Keep the guest CPU topology aligned with the host pin map so Windows does not invent SMT siblings.
- [CPU governor for pinned KVM vCPUs](VFIO/CPU-governor-for-pinned-vCPUs.md) — Hold the performance governor on the host CPUs reserved for pinned guest threads.
- [Host CPU affinity for pinned VMs](VFIO/Host-CPU-affinity-for-pinned-VMs.md) — Keep the desktop and host services off the CPUs reserved for pinned vCPU threads.
- [Raw virtio-blk boot disk](VFIO/Raw-virtio-blk-boot-disk.md) — Boot the Windows guest from virtio-blk instead of an emulated SATA qcow2 disk.
- [Debugging Windows 11 guest stalls that look like slow disk I/O](VFIO/Windows-11-guest-stalls.md) — Isolate wedged VirtIO-FS/WinFsp mounts, stale IPv6 DNS, leftover Defender filters, and Windows 11 24H2/25H2 Smart App Control MSI stalls.

## Windows development

- [Have MSBuild/nmake available in PowerShell](nmake-in-PowerShell.md) — Prepare new PowerShell sessions so MSBuild and nmake can be invoked.
- [Sign .NET assemblies during build](Sign-dotnet-assemblies-on-build.md) — Sign intermediate assemblies with signtool when assembly signing is enabled.
- [How to check which architecture I'm running](How-to-check-architecture.md) — Use `msinfo32` to tell whether a machine needs 64-bit or 32-bit drivers.
- [Fix Symbol loading for Kernel Driver minidump analysis](PDB-in-WinDbg-Session.md) — Point WinDbg at a local symbol cache and the matching driver PDB.

## HID descriptors and device IDs

- [CORSAIR GLAIVE RGB native HID Report Descriptor](CORSAIR-GLAIVE-RGB-native-HID-Report-Descriptor.md) — Captured native HID report descriptor for the CORSAIR GLAIVE RGB.
- [SIXAXIS/DualShock 3 native HID Report Descriptor](SIXAXIS-native-HID-Report-Descriptor.md) — Native firmware HID report descriptor for the SIXAXIS and DualShock 3.
- [vJoy HID Report Descriptor](vJoy-HID-Report-Descriptor.md) — Full HID report descriptor taken from the last official vJoy binaries.
- [Vendor and Product IDs used by NSS drivers](Virtual-VID-PID-used-by-NSS.md) — The vendor and product IDs used when a driver should not spoof existing hardware.
