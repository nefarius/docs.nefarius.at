# PS1/PS2 USB Adapters

DsHidMini is built for official Sony DualShock 3 / SIXAXIS and Navigation Controller hardware. Two **wired USB adapters** that let classic PlayStation 1 / PlayStation 2 pads talk to a PC are also supported. They are not DualShock 3 controllers and they do **not** work over Bluetooth.

!!! note "Clone DualShock 3 pads are a different topic"
    Aftermarket DualShock 3 lookalikes are still unsupported. See the [FAQ](FAQ.md#does-my-fake-ps3-controller-work-with-dshidmini) and [About controller compatibility](../../BthPS3/About-Controller-Compatibility.md).

## At a glance

| Adapter | Hardware IDs | First shipped | Bluetooth | Rumble | LEDs | Motion |
| --- | --- | --- | --- | --- | --- | --- |
| ShanWan PS1/PS2 USB | `VID_2563` / `PID_0575` | **v3.14.0** | No | Yes (when a pad is linked) | No | Neutral only |
| DS3-identity PS1/PS2 USB | `VID_054C` / `PID_0268`, `bMaxPacketSize0` = 8 | **v3.18.0** | No | Yes | No | Fabricated only |

Both adapters can use the same HID modes as a DualShock 3 (SDF, GPJ, SXS, DS4Windows, XInput, CGP). Pairing controls are hidden in ControlApp because there is no radio.

## ShanWan adapter (`VID_2563` / `PID_0575`)

USB device `ShanWan` / `USB WirelessGamepad`. The same VID/PID is reused by other ShanWan PC pads that speak this report.

This is **not** a DualShock 3. It does not implement the DualShock 3 USB handshake, so DsHidMini skips that sequence on purpose. A class request the firmware does not understand can make the adapter disconnect and come back as `20BC:0055` without rumble.

### What works

- Buttons, hat, analog sticks, and pressure values
- Both rumble motors when a controller is linked to the adapter (confirmed with a Retro Fighters Defender on its PS1/PS2 receiver)
- Per-device configuration (the driver publishes a synthesized address as a stable settings key)

### What does not

- Bluetooth / pairing
- LEDs
- Real motion sensors (the driver reports a fixed rest sample)

### Output stall warning

If no controller is linked on the PS1/PS2 side, rumble writes are not acknowledged. DsHidMini then short-timeouts the write instead of blocking for seconds, and ControlApp shows a warning on the device list and the detail pane. That warning clears on its own once a pad links. Whether the pad actually rumbles is decided by how it is paired to the receiver, not by DsHidMini.

## DS3-identity adapter (`VID_054C` / `PID_0268`)

USB device that **enumerates as a Sony DualShock 3** (`054C:0268`) but is a wired PS1/PS2 adapter. The sample on the shelf is sold as **Ejoyous Controller Adapter**; the same firmware is likely resold under other labels.

It is not a DualShock 3. DsHidMini classifies it from the USB device descriptor only: genuine DualShock 3 / SIXAXIS hardware reports `bMaxPacketSize0` of **64**, while this adapter reports **8**. Bluetooth is never this type.

!!! warning "The hardware ID alone is not enough"
    Searching Device Manager for `USB\VID_054C&PID_0268` can match either a DualShock 3 or this adapter. Open ControlApp and check the device type, or compare `bMaxPacketSize0` if you need to tell them apart. See [I installed everything but the controller doesn't appear](FAQ.md#i-installed-everything-but-the-controller-doesnt-appear-in-device-manager-devices-and-printers-or-the-control-app).

### What works

- DualShock 3-style input and rumble (the normal 48-byte DualShock 3 output path)
- The same HID modes as a DualShock 3
- Per-device configuration (the reported Feature `0xF2` address is used as a settings key only)

### What does not

- Bluetooth / pairing
- LEDs (those settings are hidden)
- Real motion sensors (identification and EEPROM answers are fabricated)

Older ControlApp builds that only read VID/PID still show this device as DualShock 3 / SIXAXIS. Current ControlApp reports the published device type instead.

## Related

- [ControlApp overview](ControlApp-Overview.md)
- [How to install](How-to-Install.md)
- [Frequently asked questions](FAQ.md)
