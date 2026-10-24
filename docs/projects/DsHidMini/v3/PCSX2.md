# PCSX2 Full Controller Support

Current PCSX2 on Windows reads a DualShock 3 through SDL when DsHidMini is in **SXS** mode. That mapping includes the buttons, the pressure-sensitive axes, and the vibration motors. The [SCP XInput Bridge](SCP-XInput-Bridge.md) proxy DLL is only for older PCSX2 Qt builds, described [below](#older-pcsx2-qt-builds).

This is the setup in the [PCSX2 controller guide](https://pcsx2.net/docs/configuration/controllers/) (accessed 2026-10-25), using the pressure-axis mapping merged on 2025-04-18. The dated sources are at the end of this page.

## Before you start

- A genuine DualShock 3. PCSX2 takes pressure data from an original DualShock 3. A third-party pad does not supply it, so a finished mapping on a copy still has no pressure.
- [DsHidMini installed](How-to-Install.md), with the controller connected over USB or Bluetooth.
- A current PCSX2 build. Anything from before the SDL change on 2025-04-18 belongs in [Older PCSX2 Qt builds](#older-pcsx2-qt-builds).

## Set SXS mode

SXS is the layout PCSX2's SDL backend treats as a Sixaxis / DualShock 3. The pressure axes on that path come from SXS. [SDF](HID-Device-Modes-Explained.md#sdf) is a different report, and the PCSX2 change that added this mapping calls out that SDL does not take pressure data from it. The driver's [XInput mode](HID-Device-Modes-Explained.md#xinput) is a different device again: an Xbox controller, which has no pressure-sensitive face buttons.

1. Open **DsHidMini Control App**. Changing the HID mode needs **Restart as Administrator**. The [ControlApp overview](ControlApp-Overview.md) covers that prompt.
2. Select the controller and set **HID device mode** to **SXS**. What that mode exposes is in [HID device modes](HID-Device-Modes-Explained.md#sxs).
3. Press **Apply changes**.
4. Reconnect so PCSX2 sees the mode you just applied. On USB, unplug the controller and plug it back in. On Bluetooth, Apply drops the link; press the PS button to turn the pad back on.
5. If PCSX2 was already open, quit it and start it again so it enumerates the reconnected device.

USB and Bluetooth each keep their own HID mode. Set SXS for the connection you play on, and check it again when you move between the cable and wireless.

## Map the controller

1. In PCSX2, open **Settings → Controllers**.
2. Enable the **SDL** input source.
3. Open **Controller Port 1** (DualShock 2).
4. Press **Automatic Mapping**. Older PCSX2 windows label this button **Automatic Binding**.
5. Select the **SDL** entry for this controller, then close the window.

PCSX2 fills that port from the SDL device: buttons, pressure axes, and the large and small vibration motors. This path does not use `XInput1_3.dll`. In the device list, choose the **SDL** entry. The **XInput** entries are the older-build fallback in the next section.

## Check pressure and rumble

The Qt window has no pad tester. PCSX2's controller guide, in **Testing your input mapping**, links a PS2 Pad Test homebrew that draws every DualShock 2 axis. Drop that onto the PCSX2 window if you want the axes on screen.

In a game that reads face-button pressure, a light press has to stay a light press. The check reported with the older setup, on 2022-05-30, still applies: in *Metal Gear Solid 2*, aim with Square and ease off the button. With pressure working, the gun stays quiet as the button comes up.

Automatic Mapping also assigns **Large Motor** and **Small Motor**. If the motors stay still, run **Automatic Mapping** again and choose the SDL entry for this pad. When a motor field is empty, open it and pick the motor that belongs to that SDL device.

## Older PCSX2 Qt builds

Use this only when PCSX2 is older than the SDL pressure change merged on 2025-04-18. On those builds the working pressure setup is **SXS** plus the [SCP XInput Bridge](SCP-XInput-Bridge.md).

A plain XInput pad has no channel for pressure-sensitive face buttons. The proxy still shows up as an Xbox-style controller, and it adds a pressure extension that those PCSX2 builds read. The driver's own XInput mode does not add that extension, so a mode switch with no DLL leaves the face buttons digital.

1. Keep the controller in **SXS**. Reconnect after any mode change, the same way as in [Set SXS mode](#set-sxs-mode).
2. Download the `XInput1_3.dll` that matches the PCSX2 executable. A 64-bit build takes the x64 DLL. The x86 and ARM64 files are listed with it under [Latest downloads](SCP-XInput-Bridge.md#latest-downloads). The wrong architecture fails with an error instead of a working controller.
3. Copy `XInput1_3.dll` into the folder that contains the PCSX2 executable, beside that `.exe`.
4. Quit PCSX2 completely, then start it so this copy of the DLL is the one it loads.
5. Open **Settings → Controllers** and enable the **XInput** input source. Older builds label that checkbox **Enable XInput Source**.
6. Open **Controller Port 1** (DualShock 2), press **Automatic Mapping** (**Automatic Binding** on those older windows), and select **XInput-0 (XInput Controller 0)**. When another XInput device is already connected, choose the index for this pad.
7. Close the window and check pressure the same way as above.

## If something does not respond

- **No pressure.** Check the HID mode on the connection you are using. USB and Bluetooth are stored separately, and a pad that is SXS on the cable can still be in another mode over Bluetooth. Reconnect after **Apply changes**, then start PCSX2 again. On a current build, the bound device is the **SDL** entry. On an older Qt build, it is the **XInput** entry from the proxy, which means the matching DLL has to be the one PCSX2 loaded. A third-party controller still will not produce pressure data once the mapping looks complete.
- **No rumble.** Run **Automatic Mapping** again on the device you play with. Fill **Large Motor** and **Small Motor** from that same device when the fields are empty.
- **Another pad got the port.** Extra controllers, and any other XInput device, change which name in the list is yours. **XInput-0** is this DualShock 3 only when it is the first XInput device.
- **The proxy DLL changed nothing.** Match x64, x86, or ARM64 to the executable, put `XInput1_3.dll` in that executable's folder, and start PCSX2 after the file is in place. On a current build, pressure comes from the SDL mapping above; the DLL is the setup in [Older PCSX2 Qt builds](#older-pcsx2-qt-builds).

Pre-Qt PCSX2, the wxWidgets builds with the LilyPad plugin, is a separate procedure: **SDF** mode and DirectInput. Those steps remain in the [FAQ](FAQ.md#how-do-i-set-the-controllers-pressure-buttons-in-pcsx2). Current Qt builds use the SDL steps on this page.

## Sources

- [Controllers | PCSX2](https://pcsx2.net/docs/configuration/controllers/), accessed 2026-10-25. The Windows pressure setup there is DsHidMini in SXS mode, the SDL input source, and **Automatic Mapping** of the matching SDL device. Pressure sensitivity is limited to an original DualShock 3. The same guide says **Automatic Mapping** fills the vibration motors for an input source that supports it.
- [PCSX2 pull request #12402](https://github.com/PCSX2/pcsx2/pull/12402), merged 2025-04-18. Enables SDL's Sixaxis driver support on Windows, DsHidMini in SXS mode included, and makes Automatic Mapping bind the pressure axes. The pull request states that SDL pressure on Windows is the SXS layout, and that SDF differs enough that SDL does not use it for this.
- [PCSX2 issue #6233](https://github.com/PCSX2/pcsx2/issues/6233). CookiePLMonster, 2022-05-29: pair SXS mode with DsHidMini's `XInput1_3.dll` in the PCSX2 directory. ja3h, 2022-05-30: confirmed that pair for pressure on a wired DualShock 3 and again over Bluetooth, and reported that SDF was the wrong mode for it.
