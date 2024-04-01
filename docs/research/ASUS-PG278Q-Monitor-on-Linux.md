# ASUS PG278Q Monitor on Linux

The action in this article have been conducted under the following conditions:

Property | Value
---|---
Date | March 2024
Kernel | 5.15.0-101-generic
Distribution | Linux Mint 21.3 Virginia

## Problem

I am running a dual-monitor setup with the [ASUS ROG Swift 27" 1440P Gaming Monitor (PG278Q)](https://www.amazon.com/27-inch-Monitor-PG278Q-Response-Display/dp/B00MSOND8C) as my primary display and have been quite satisfied with it for many years. In a recent adventure of installing [Linux Mint 21.3](https://www.linuxmint.com/) I suddenly was confronted with a couple of problems. First I tried it on my AMD Radeon 6900 XT on different DisplayPort connectors, and each time it was detected as an "Unknown Display" and could only display a meek 640x480 and 60Hz. I also temporarily tried an NVIDIA Quadro K2200, which didn't even produce any display at all. After some brief web searches I found [some fellow sufferers reporting the same issue](https://www.reddit.com/r/linux_gaming/comments/17oi5tk/comment/k83gmai/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button) and a proposed solution. In short, some component in the Linux kernel (graphics driver, firmware?) isn't able to read the [EDID](https://en.wikipedia.org/wiki/Extended_Display_Identification_Data) of the monitor, so the system doesn't know the modes supported by the plugged in device. The post is unfortunately incomplete and misleading, hence the need for this article.

## Solution

Thankfully we can assist the kernel by providing the EDID binary blob ourselves! The following steps are tailored towards users of GRUB2 so depending on your distribution they might not apply 1:1.

### Add EDID to boot image

We need to make sure that the EDID content (which would normally be queried directly from the monitor) is available to the kernel during boot.

- Download the [PG278Q.bin](./PG278Q.bin) and copy it to `/usr/lib/firmware/edid`  
  (you might need to create the directory first)
- Create a new shell script at `/etc/initramfs-tools/hooks/edid` with the following content:  
  ```bash
  #!/bin/sh
  if [ -d /lib/firmware/edid ]; then
    cp -r --parents /lib/firmware/edid ${DESTDIR}
  fi
  ```
- Make it executable:  
  ```bash
  sudo chmod +x /etc/initramfs-tools/hooks/edid
  ```
- Update the boot image (this will make the EDID file available during boot):  
  ```bash
  sudo update-initramfs -u
  ```

### Configure DisplayPort to use EDID file

Now for the tricky part; how to configure the correct DisplayPort connector to use the EDID file. This sounds simple in practice but can get rather tricky, especially in multi-GPU setups. Online resources simply recommend to use `xrandr` to look for the port with only the one `640x480` available mode (for example on `DisplayPort-0`). These names and indices do not necessarily correspond to the connector name we need to configure kernel parameters with though!

Here's a reliable way to find the correct connector:

- Unplug the monitor (if you do not have a 2nd monitor, you can run these steps via SSH as well)
- Get a list of all ports and their status:  
  ```bash
  find /sys/devices -name "edid" | awk -F/ -vOFS=/ 'NF-=1' | xargs -I{} sh -c 'echo -n {}:" " && cat "{}"/status'
  ```
    - This might produce output similar to:  
      ```bash
      /sys/devices/pci0000:00/0000:00:03.2/0000:0d:00.0/drm/card0/card0-HDMI-A-1: disconnected
      /sys/devices/pci0000:00/0000:00:03.2/0000:0d:00.0/drm/card0/card0-DP-2: connected
      /sys/devices/pci0000:00/0000:00:03.2/0000:0d:00.0/drm/card0/card0-DP-3: disconnected
      /sys/devices/pci0000:00/0000:00:03.2/0000:0d:00.0/drm/card0/card0-DP-1: disconnected
      ```
- Now plug in the monitor and run the snippet again. You should now see one of the entries (e.g. `card0-DP-1`) change from `disconnected` to `connected`, so **`DP-1` is the value we need!**
- Armed with that knowledge edit `/etc/default/grub`, modify the line `GRUB_CMDLINE_LINUX_DEFAULT` and append `drm.edid_firmware=DP-1:edid/PG278Q.bin video=DP-1:e"` where **DP-1** matches whatever your particular connector name is.
- Update GRUB:  
  ```bash
  sudo update-grub
  ```

Now time for a reboot and you should be able to enjoy the full set of 1440p @ 144Hz again!
