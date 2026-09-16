# Looking Glass B7 with IVSHMEM

The action in this article has been conducted under the following conditions:

Property | Value
---|---
Date | September 2026
Kernel | 6.8.0-139-generic
Distribution | Linux Mint 22.3
QEMU | 8.2.2
libvirt | 10.0.0
Looking Glass | B7 (`27fe47cb`, 2025-03-06)
kvmfr | 0.0.9 (DKMS)

Official docs: [libvirt/QEMU](https://looking-glass.io/docs/B7/install_libvirt/), [kvmfr](https://looking-glass.io/docs/B7/ivshmem_kvmfr/), [Windows host](https://looking-glass.io/docs/B7/install_host/), [Linux client](https://looking-glass.io/docs/B7/install_client/). Related: [Windows 11 Gaming VM with GPU pass-thru](./Windows-11-Gaming-VM.md).

## Problem

A VFIO Windows guest paints on the passed-through GPU. The host cannot see that framebuffer through Spice or virt-manager. Looking Glass copies frames over IVSHMEM so the Linux desktop can display the guest with low latency.

The Ubuntu / Mint `looking-glass-client` package is **B6**. The Windows host installer and the Linux client must be the **same** stable version. B7 is current stable.

Do not run two domains against the same IVSHMEM file (or the same GPU) at once.

Rust `virtiofsd` 1.10 (Ubuntu / Mint 22) dies with `Illegal seek` / `vhost_set_mem_table failed` if the domain also maps `/dev/kvmfr0`. That char device is not seekable, so the daemon exits and the guest share disappears. Use **standard `/dev/shm` IVSHMEM** on any guest that also has virtiofs. Keep kvmfr for domains that do not use virtiofs.

## Host: shared memory

A 32 MiB file is enough for 1080p SDR. Use 64 MiB for 1440p SDR.

```text
# /etc/tmpfiles.d/10-looking-glass.conf
f /dev/shm/looking-glass 0660 <user> kvm -
```

```bash
sudo systemd-tmpfiles --create /etc/tmpfiles.d/10-looking-glass.conf
```

If AppArmor is enforcing, allow `/dev/shm/looking-glass rw,` in `/etc/apparmor.d/local/abstractions/libvirt-qemu`.

## Domain XML

Keep Spice for input and clipboard, drop the emulated QXL head (passthrough GPU is the only display), drop the USB tablet, and add virtio keyboard/mouse. Use libvirt `<shmem>`, not a qemu:commandline kvmfr backend.

```xml
<domain type="kvm">
  <!-- … -->
  <channel type="spicevmc">
    <target type="virtio" name="com.redhat.spice.0"/>
  </channel>
  <input type="mouse" bus="ps2"/>
  <input type="keyboard" bus="ps2"/>
  <input type="mouse" bus="virtio"/>
  <input type="keyboard" bus="virtio"/>
  <graphics type="spice" autoport="yes">
    <listen type="address"/>
    <image compression="off"/>
    <gl enable="no"/>
  </graphics>
  <sound model="ich9">
    <audio id="1"/>
  </sound>
  <audio id="1" type="spice"/>
  <video>
    <model type="none"/>
  </video>
  <shmem name="looking-glass">
    <model type="ivshmem-plain"/>
    <size unit="M">32</size>
  </shmem>
  <memballoon model="none"/>
</domain>
```

`virsh define` the inactive XML. virt-manager’s console will be blank after `video none`; that is expected.

## Linux client (B7 from source)

Download the stable **source** artifact from [looking-glass.io/downloads](https://looking-glass.io/downloads), not `apt install looking-glass-client`.

```bash
mkdir -p client/build
cmake -S client -B client/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build client/build -j"$(nproc)"
cmake --install client/build
looking-glass-client --help   # banner: Looking Glass (B7)
```

B7 defaults `app:shmFile` to `/dev/kvmfr0`. Point it at the shm file instead. The client does not save the last window position; `win:position` is only the startup coordinate (`center` or `<left>x<top>`).

```ini
# ~/.config/looking-glass/client.ini
[app]
shmFile=/dev/shm/looking-glass

[win]
size=1920x1080
position=2112x180
autoResize=no
fullScreen=no
maximize=no
borderless=no
```

`win:position` is `<left>x<top>` in the combined desktop. `0x0` plus `1920x1080` fills a 1080p output and the window manager treats that as fullscreen. The values above park a 1080p window on a 2560×1440 display at `+1920+0`. `win:autoResize=yes` follows the guest framebuffer, not a fixed 1080p.

## Windows host (B7)

1. Start the domain so the new IVSHMEM device is present.
2. Copy `looking-glass-host-setup.exe` from the B7 **Windows Host** artifact into the guest (virtiofs or ISO).
3. Run the installer **as Administrator**. Since B6 the installer ships the IVSHMEM driver.
4. Install the virtio **input** driver (`vioinput`) from virtio-win if Device Manager shows unknown keyboard/mouse devices.
5. Optional clipboard: Spice guest tools, with the `com.redhat.spice.0` channel above.

Host log on failure: `%ProgramData%\Looking Glass (host)\looking-glass-host.txt`.

## Guest needs a display sink (AMD)

Post-GCN AMD GPUs power down the display block when nothing is plugged in. DXGI then has no desktop to capture, so the Linux client stays on the splash / blank even though both Looking Glass processes are running.

`video none` plus GPU passthrough does **not** count as a monitor. Attach a real display to the guest GPU, or a DisplayPort/HDMI dummy plug. After the sink appears, restart the Looking Glass host service (or reboot the guest) and reopen the client.

Stable B7 has no Indirect Display Driver. Bleeding-edge builds ship a Windows IDD if you want a virtual sink later.

## Run

```bash
looking-glass-client
```

If the client says it is waiting for the host, the Windows service is not running or IVSHMEM is missing. If both ends are running but the picture is still empty, check the guest GPU has a sink. If the picture is cropped at the bottom, the IVSHMEM size is too small for that resolution.

If virtiofs dies with `Illegal seek` / `vhost_set_mem_table failed`, the domain is still mapping `/dev/kvmfr0`. Remove the kvmfr `qemu:commandline` block.
