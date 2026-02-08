# Installation Guide (Shibari Edition)

!!! attention "🚨 Obsolete solution 🚨"
    [DsHidMini](../DsHidMini/index.md) (official successor) has been released, please use that instead! This article will remain online for historic reasons but use is discouraged as no more updates will follow!

## What is this?

Ever wanted to use those pesky, outdated yet lovely game controller devices shipped with your PlayStation® 3 on Windows without constantly tripping over wires? Well, fear no more—you have come to the right place. This guide covers the software you need, and it will only cost you a few minutes of your time.

BthPS3 emerged from [research and development](https://web.archive.org/web/20220630164947/https://forums.vigem.org/topic/242/bluetooth-filter-driver-for-ds3-compatibility-research-notes/) by [Nefarius](https://github.com/nefarius), known for building software that is not always obvious to install or remove.

If that sounds useful, read on.

## What do you need?

You need **Windows 10** (or later) and a Bluetooth USB device or integrated card (e.g. in a laptop) running **stock** drivers—no [ScpToolkit](https://github.com/nefarius/ScpToolkit), no [AirBender](https://github.com/nefarius/AirBender). (You will install BthPS3 and related components as described below.)

![802ebf28-a2a8-4c78-902d-1370a3d01b25-image.png](../../assets/uploads/files/802ebf28-a2a8-4c78-902d-1370a3d01b25-image.png)

## How to install

!!! info "Download setup for Windows 10"
    [Latest BthPS3 Bluetooth Drivers](https://github.com/nefarius/BthPS3/releases/latest)

1. Download and run the BthPS3 setup. Follow the installer; it will guide you through the steps.
2. **Plug in your Bluetooth dongle now** if you have not already.
3. If you have an **integrated Bluetooth card** (e.g. in a laptop), **make sure it is turned on** before continuing.

If Bluetooth is not available or not on, the setup will fail. Ensure the Bluetooth radio is present and enabled, then run the setup again.

## What to do next

After BthPS3 is installed, you need Shibari and a few other components.

### Get the files

Download and extract the following somewhere on your PC:

- **Shibari:** Latest `Shibari.zip` [from the build server](https://buildbot.nefarius.at/builds/Shibari/master/) (pick the highest version number). Shibari acts as the middle layer between the drivers and your applications.
- **FireShock:** Latest `FireShock.zip` [from here](https://downloads.nefarius.at/projects/FireShock/stable/). Required for USB connection and automatic pairing.
- **ViGEm Bus Driver:** Latest release [from GitHub](https://github.com/ViGEm/ViGEmBus/releases/latest). Required so the devices can be presented as Xbox 360 or DualShock 4 controllers to games.

### Install the drivers

- Extract the **FireShock** archive and run the included `dpinst` or `dpinst64` to install the USB driver.
- Run the **ViGEm Bus Driver** installer and complete the setup.

### Run Shibari

Extract the **Shibari** archive and open the resulting folder. Run `Shibari.Dom.Server.exe`. Your connected DS3 should then appear as a virtual Xbox 360 and DualShock 4 controller in games. **Keep Shibari running** for everything to work. The FAQ below explains how to run it as a Windows service so you do not have to start it manually each time.

![a86fcc5f-bfd5-4c29-9b47-633d7ffbdc72-image.png](../../assets/uploads/files/a86fcc5f-bfd5-4c29-9b47-633d7ffbdc72-image.png)

## FAQ

### Is this official Sony software?

No. This is a community project, not affiliated with Sony. It started as a research project and was developed into something usable for gamers.

### Does BthPS3 phone home?

No. Earlier versions included an updater that checked for updates; that was removed in BthPS3 v1.3.x. BthPS3 does not send data to external servers.

### Why only Windows 10 and later?

Driver signing and testing across multiple Windows versions is complex. Support was limited to Windows 10 and later to keep the project maintainable. As of [this commit](https://github.com/nefarius/BthPS3/commit/7959c119609138b9f5776ac99804f6062771ee4a), Windows 7 is no longer supported due to a dependency that does not exist on older Windows versions.

### Do I still need Shibari?

No. [Use DsHidMini instead](../DsHidMini/index.md)—it replaces Shibari and FireShock and does not require a separate server process.

### How do I get pressure-sensitive buttons in PCSX2?

[DsHidMini](../DsHidMini/index.md) supports that; Shibari/FireShock do not.

### Can I use motion controls?

Motion support is out of scope for this (obsolete) stack. Use [DsHidMini](../DsHidMini/index.md) for motion and other advanced features.

### I want a battery indicator / quick disconnect / other SCP-like features

[DsHidMini](../DsHidMini/index.md) provides those features. This Shibari-based setup does not.

### I sometimes need to power on the controller twice before it stays connected

That is due to how connection state is stored in the Microsoft Bluetooth stack when the driver attaches. The workaround is to turn the controller on again.

### The setup version does not match the driver version

That is intentional. The installer (setup) is updated separately from the driver; not every installer change requires new driver binaries.

### I want DualShock 4 emulation, not Xbox 360

Open `settings.json` in your Shibari folder and see the comments in the `"sinks"` section to configure the output device type.

### My DS3 no longer works in PS Now

FireShock and Sony’s official `sixaxis` driver used by PS Now cannot both be active. If you need USB support for PS Now, uninstall FireShock. For a solution that can coexist with PS Now, use [DsHidMini](../DsHidMini/index.md) instead.

![Uninstall FireShock](../../assets/uploads/files/7f5092c2-15e8-4dd8-bdb1-5a300607db15-image.png)

### My DS4 will not connect anymore

With BthPS3 installed, reconnecting a DS4 often requires two attempts: turn the DS4 on, let it turn off after a second or two, then within about 10 seconds turn it on again. It should then connect. For full details, see the [DualShock 4 FAQ](DualShock-4-FAQ.md).

### How do I keep Shibari running in the background?

You can install Shibari as a Windows service so it runs without keeping a window open.

1. Open [PowerShell as Administrator](https://www.top-password.com/blog/5-ways-to-run-powershell-as-administrator-in-windows-10/).
2. Go to the folder where you extracted Shibari and run:
   ```powershell
   .\Shibari.Dom.Server.exe install
   ```
   ![Shibari install](../../assets/uploads/files/bca87e6e-473e-4445-8f6b-bc7017518e91-image.png)
3. Start the service:
   ```powershell
   Start-Service Shibari.Dom.Server
   ```
4. Confirm it is running:
   ```powershell
   Get-Service Shibari.Dom.Server
   ```
   ![Shibari service](../../assets/uploads/files/b99c4a26-c6fa-4c3d-8186-f63d21412955-image.png)

### My controller randomly presses buttons or the sticks jitter

This is not a software bug. Erratic input usually comes from the controller hardware—faulty parts, wear, or damage. Try another controller or USB cable. Third-party or counterfeit controllers are also more likely to misbehave; genuine or higher-quality hardware tends to be more reliable.

---

!!! important "Copyright (C) 2018-2021 - Nefarius Software Solutions e.U."
    This is a community project and not affiliated with Sony Interactive Entertainment Inc. in any way.

    "PlayStation", "PSP", "PS2", "PS one", "DUALSHOCK" and "SIXAXIS" are registered trademarks of Sony Interactive Entertainment Inc.
