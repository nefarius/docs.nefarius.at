# Looking Glass B7 with IVSHMEM

The action in this article has been conducted under the following conditions:

Property | Value
---|---
Date | September 2026 (updated November 2026)
Kernel | 6.8.0-139-generic
Distribution | Linux Mint 22.3
Mesa | 25.2.8 (`radeonsi`)
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

Looking Glass requires a power-of-2 IVSHMEM size large enough for double-buffered frames plus header and cursor metadata:

IVSHMEM size | Max resolution (SDR, 32-bit) | Max resolution (HDR, 16-bit float)
---|---|---
`32` MiB | 1920×1080 | —
`64` MiB | 2560×1440 | 1920×1080
`128` MiB | 3840×2160 (4K) | 2560×1440
`256` MiB | 5120×2880+ | 3840×2160 (4K)

Use `128` MiB if you want 1440p HDR or 4K SDR headroom without re-editing the XML later. Keep the `<shmem>` size identical across every domain that shares `/dev/shm/looking-glass`, and apply the change with a full domain shutdown and start (not an in-guest reboot).

!!! warning "Resizing an existing `/dev/shm/looking-glass` file"
    QEMU only sizes an empty (0-byte) backing file automatically. If `/dev/shm/looking-glass` still has the previous size (for example 32 MiB from an earlier boot), starting the domain fails with `backing store size 0x2000000 does not match 'size' option 0x8000000`. Shut down every domain that uses `/dev/shm/looking-glass` and close `looking-glass-client` before resetting the file to 0 bytes, then start the domain:

    ```bash
    truncate -s 0 /dev/shm/looking-glass
    ```

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
    <size unit="M">128</size>
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

[input]
grabKeyboardOnFocus=yes
ignoreWindowsKeys=no

[egl]
preset=Upscaling
```

`win:position` is `<left>x<top>` in the combined desktop. `0x0` plus `1920x1080` fills a 1080p output and the window manager treats that as fullscreen. The values above park a 1080p window on a 2560×1440 display at `+1920+0`. `win:autoResize=yes` follows the guest framebuffer, not a fixed 1080p.

`input:grabKeyboardOnFocus` sends host combos such as Win+R into the guest as soon as the Looking Glass window has keyboard focus (no Scroll Lock). `ignoreWindowsKeys=no` is the default and must stay off. Hover alone is not enough on a click-to-focus desktop; enable sloppy/mouse focus in the window manager if the pointer entering the window should grab keys. Leave `input:captureOnFocus` off unless the mouse should lock into the window on focus.

`egl:preset` loads a saved EGL filter preset from `~/.config/looking-glass/presets/` automatically at startup (the client otherwise starts with no preset loaded). Create the preset through the overlay (`Right Ctrl`+`O` or `Scroll Lock`+`O` → **EGL Filters** → **Save preset as…**) instead of hand-editing files under `presets/`.

## EGL upscaling (FSR1) black screen on Mesa 25.x {#egl-fsr1-mesa-black-screen}

### Symptom

- **AMD FidelityFX FSR**: works while the client window is at or below the guest resolution (because `ffxFSR1` is bypassed when no upscaling is needed), then turns the rendered image **solid black** the moment the window grows larger than the guest framebuffer.
- **AMD FidelityFX CAS**: runs at any resolution without an upscaling check, so enabling it turns the rendered image **solid black** immediately regardless of window size.

### Cause

Looking Glass B7 (`27fe47cb`, 2025-03-06) compiles its EGL post-processing shaders as GLSL ES 3.00 (`#version 300 es`) with `precision highp float;` only, leaving `int` and `uint` at GLSL ES's default `mediump` (16-bit). Mesa 25.x on AMD (`radeonsi`) began honoring 16-bit `mediump int` in fragment shaders ([Mesa #12990](https://gitlab.freedesktop.org/mesa/mesa/-/issues/12990#note_3038479)).

AMD FidelityFX FSR1 (`ffx_fsr1_easu.frag`, `ffx_fsr1_rcas.frag`) and CAS (`ffx_cas.frag`) pass packed 32-bit IEEE-754 float parameters through `uvec4 uConsts` and unpack them with 32-bit integer operations. Truncating those constants to 16-bit zeroes or corrupts them, producing a black frame.

### Fix

Apply upstream commit [gnif/LookingGlass@60d7c849](https://github.com/gnif/LookingGlass/commit/60d7c849723ba9d044388d00e9a12ede056ff8de) (`[client] egl: make int highp in fragment shaders`) to the B7 source tree before building. Patching B7 instead of switching the client to `master` keeps protocol compatibility with the stable B7 Windows host service.

```bash
curl -fL "https://looking-glass.io/artifact/B7/source" -o looking-glass-B7.tar.gz
tar xzf looking-glass-B7.tar.gz
cd looking-glass-B7
curl -fL "https://github.com/gnif/LookingGlass/commit/60d7c849723ba9d044388d00e9a12ede056ff8de.patch" \
  -o highp-int.patch
# Skip the AUTHORS hunk (line numbers differ on B7) and apply only the EGL shader hunks
awk '/^diff --git /{skip=($0 ~ /AUTHORS$/)} !skip' highp-int.patch | patch -p1

cmake -S client -B client/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build client/build -j"$(nproc)"
```

Verify that the compiled binary contains `precision highp int;` in all 11 fragment shaders, then install it atomically (overwriting a running binary in place fails with `ETXTBSY`):

```bash
strings client/build/looking-glass-client | grep -c "precision highp int;"   # expected: 11
install -m 0755 client/build/looking-glass-client "$HOME/.local/bin/looking-glass-client.new"
mv -f "$HOME/.local/bin/looking-glass-client.new" "$HOME/.local/bin/looking-glass-client"
```

Relaunch `looking-glass-client`, enable **AMD FidelityFX FSR** in the **EGL Filters** tab, save a preset (for example `Upscaling`), and reference it via `[egl] preset=Upscaling` in `~/.config/looking-glass/client.ini`.

!!! note "Native resolution vs. host-side FSR1"
    Host-side FSR 1.0 is purely spatial, so raising IVSHMEM to `64` or `128` MiB and running the guest at native monitor resolution still produces sharper desktop text and lets games use temporal upscalers (DLSS, FSR 2+, XeSS). Keep the FSR1 preset enabled as a fallback: it remains inactive when the captured frame matches the client output and activates only when the guest framebuffer (for example, a lower-resolution fullscreen mode) or an earlier filter's output (such as the Downscaler filter) is smaller than the client output. A smaller game window inside a native-resolution guest desktop does not reduce the captured frame size.

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
