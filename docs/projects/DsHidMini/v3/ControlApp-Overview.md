# ControlApp Overview

ControlApp is the companion application that ships with DsHidMini **v3.9.0** and newer. The driver keeps working while ControlApp is closed. Use it to confirm a controller is seen, change HID modes and per-device settings, run first-run Bluetooth setup, and collect diagnostics.

On **v3.9.0** or newer, open **DsHidMini Control App** from the Start Menu under **Nefarius Software Solutions** → **DsHidMini**. It needs the [.NET Desktop Runtime 10 (x64)](https://dotnet.microsoft.com/en-us/download/dotnet/10.0) — any **10.0.x** release is accepted. If you want a newer build than the one setup installed, download [ControlApp.exe](https://buildbot.nefarius.at/builds/DsHidMini/latest/bin/ControlApp.exe) from the build server.

!!! note "Administrator for changes"
    You can open ControlApp and look at devices without elevation. Changing HID mode, shared profiles, pairing, or BthPS3 settings needs **Restart as Administrator**. After a HID-mode change, reconnect the controller so the new mode becomes active.

## First-run setup

Starting with **v3.16.0**, the first launch opens **Let's connect your controller**. This one-time wizard checks Bluetooth, BthPS3, and a USB-connected pad, then walks you through pairing so the controller can reconnect on its own.

Typical checks include:

- Bluetooth is on
- BthPS3 is installed and new enough
- The BthPS3 filter is loaded
- Required BthPS3 settings are correct (RAW PDO off, PSM patching on)
- A pairing-eligible controller is connected over USB

If a required BthPS3 setting is wrong, **Apply automatic fix** can correct it when ControlApp is running as Administrator.

### USB-only PCs

If this PC has no Bluetooth and you only use USB, choose **Continue with USB only**. That path is available from **v3.19.0**. **Skip setup** is also available, but you must confirm that getting wireless working afterwards is your responsibility and that support will be declined for a skipped setup.

You can leave first-run setup by exiting ControlApp; the wizard comes back on the next launch until it is finished or skipped.

## Devices

The device list shows every DsHidMini controller that is currently connected. Select one to:

- Change [HID device mode](HID-Device-Modes-Explained.md)
- Adjust LEDs, rumble, stick deadzone, idle disconnect, and the wireless quick-disconnect combo
- Pair or disconnect Bluetooth (hidden for adapters that have no radio)
- Power off a wired controller
- Watch live motion when the pad reports it
- See the live **input report rate** on the device UI

ShanWan adapters can also show an **output stall** warning while no pad is linked on the PS1/PS2 side. That is expected and clears when a controller links. See [PS1/PS2 USB adapters](PS1-PS2-USB-Adapters.md).

### Input tester and rumble tester

These testers talk to the driver over IPC, so they work in **any HID mode** — you do not have to switch to XInput just to confirm buttons or motors.

- **Input tester** — live buttons, sticks, and related inputs
- **Rumble tester** — left and right motors without launching a game

Both need a published device slot and a driver that exposes IPC. If a button is disabled, the tooltip explains why.

### Info tab

The **Info** tab shows identification and two independent authenticity approximations:

- Bluetooth address / chip-vendor (OUI) check
- Feature `0x01` identification pattern

Neither result is a genuine-or-fake verdict. Aftermarket pads can copy a Sony-looking address, and USB vendor/product IDs are almost always copied from Sony. ControlApp caches the published [OUI list](../genuine_oui_db.json) so the address check can still run if the download is temporarily unavailable.

**Export diagnostics** on the same tab is the preferred way to collect a support bundle. See [Collecting diagnostics](Collecting-Diagnostics.md).

## Bluetooth diagnostic

The same guided Bluetooth checks used at first run are also available later when a pad will not stay connected wirelessly. The wizard can create a diagnostic package if a step fails.

For wireless connection issues also read the [BthPS3 FAQ](../../BthPS3/Frequently-Asked-Questions.md).

## Profiles and settings

- **Profiles** — per-device overrides plus a global default used for new devices
- **Settings** — tray behavior, Defender Bluetooth auto-switch, driver IPC, BthPS3 status/repair, and update checks

Application preferences live in `%AppData%\ControlApp.json`. Driver configuration lives under `%ProgramData%\DsHidMini`.

### ControlApp will not start after editing settings

If `%AppData%\ControlApp.json` is empty or not valid JSON, ControlApp copies the broken file to a timestamped `ControlApp.json.corrupt-...` backup and continues with defaults. It should not crash on startup. You can delete the backup after you no longer need it.

## Related

- [How to install](How-to-Install.md)
- [HID device modes explained](HID-Device-Modes-Explained.md)
- [Collecting diagnostics](Collecting-Diagnostics.md)
- [Frequently asked questions](FAQ.md)
