# Collecting Diagnostics

When a DualShock 3, SIXAXIS, Navigation Controller, or supported adapter misbehaves, send a **ControlApp diagnostics export** first. That bundle already includes identification reports, USB descriptors when available, and a short live capture. Manual USB traces remain a fallback.

!!! info "Minimum version"
    **Export diagnostics** needs DsHidMini **v3.19.0** or newer, with ControlApp from that same release line. Older installs can still follow [Debugging the drivers](Debugging-the-drivers.md).

## Preferred: export from ControlApp

1. Connect the controller **by USB** and open **DsHidMini Control App**.
2. Select the controller.
3. Open the **Info** tab and click **Export diagnostics**.
4. Leave **Mask Bluetooth addresses and the serial number** ticked unless a maintainer asked you not to.
5. Click **Start export**. The app reads descriptors, feature reports, and EEPROM pages, then asks you to keep the controller flat, tilt it, and shake it for about 15 seconds.
6. Choose where to save the ZIP and send that file.

If the driver is too old, the controller is on Bluetooth, or a read fails, the export still finishes with whatever data is available and records the gaps in `summary.json` inside the ZIP. A partial export is still useful.

First-run setup and the Bluetooth diagnostic wizard can also create a diagnostic package when a pairing step fails. That package is complementary; it does not replace an Info-tab export for hardware investigation.

## When to use driver traces instead

Use [Debugging the drivers](Debugging-the-drivers.md) when:

- ControlApp cannot start or cannot see the device at all
- you need a live ETW session while reproducing a race or disconnect
- a maintainer asked for an `events.tsv` / `.etl` capture

Starting with **v3.16.0**, the DsHidMini MSI registers the ETW instrumentation manifest during install (and unregisters it on uninstall). You still enable verbose tracing once as described on that page.

## Manual USB capture (fallback)

Use this only when ControlApp cannot run the probe, or when a maintainer asks for a raw USB startup capture.

Please complete both captures in order:

1. [Wireshark](https://www.wireshark.org/download.html) + **USBPcap** while DsHidMini is still installed
2. The DsHidMini diagnostic tool after temporarily binding **this controller only** to WinUSB with [Zadig](https://zadig.akeo.ie/)

!!! danger highlight "Change only the controller"
    Only change the driver for the USB device whose ID is **054C:0268** (or the ShanWan adapter `2563:0575` if that is the device under test). Choosing a keyboard, mouse, USB hub, or another device in Zadig can make that device stop working until its driver is restored.

### What to send

Send these together in one ZIP:

- the Wireshark `.pcapng` capture
- the diagnostic `.txt` file
- the diagnostic `_stream.csv` file
- a photo of the controller's rear label, and board photos if it has already been opened

### Privacy

USBPcap records traffic from every USB device on the selected host controller. During the short capture:

- close password managers and other sensitive applications
- do not type passwords or other private text
- disconnect unnecessary USB devices where practical
- do not browse files on USB storage

The diagnostic tool hides the unique part of the controller Bluetooth address and the complete paired-host address in its text report. The Wireshark capture remains unredacted.

### Capture USB traffic

1. Connect the controller directly to the PC by USB. Avoid a hub if possible.
2. Start Wireshark as Administrator, open **Capture → Options**, and find the `USBPcap` interface whose **Attached USB Devices** list contains the controller.
3. Unplug the controller, start the capture, then plug it back into the same port.
4. Wait about five seconds, press the PS button once, then for about 15 seconds press each face button, move both sticks, and tilt the pad.
5. Stop the capture and save the **complete** file as `ds3-usb-capture.pcapng`. Do not export a filtered subset.

### Temporary WinUSB + diagnostic tool

1. Keep the current DsHidMini installer available for recovery.
2. Disconnect every other DualShock 3 or SIXAXIS.
3. In Zadig, enable **Options → List All Devices**, select the controller, confirm the USB ID, choose **WinUSB**, then **Replace Driver**.
4. Unplug and reconnect the controller once.
5. Run `Run-Diagnostics.cmd` from the provided diagnostic ZIP and follow the orientation prompts.
6. Keep both newly created files in its `captures` folder: one `.txt` and one `_stream.csv`.

### Restore DsHidMini

1. In Device Manager, find the controller under **Universal Serial Bus devices**.
2. Uninstall **only that device**. Enable **Attempt to remove the driver for this device** if Windows offers it.
3. Unplug and reconnect the controller.
4. Confirm it appears again in ControlApp.

If it does not return, run the current DsHidMini installer and reconnect. Changing this single device to WinUSB does not alter its firmware.

## Related

- [ControlApp overview](ControlApp-Overview.md)
- [Debugging the drivers](Debugging-the-drivers.md)
- [Frequently asked questions](FAQ.md)
