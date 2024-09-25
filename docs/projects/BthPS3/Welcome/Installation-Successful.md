# BthPS3 installed successfully

Congratulations on your BthPS3 installation!

## Next Steps

You will most likely want to install the **companion solution [DsHidMini](../../DsHidMini/index.md)** (if you haven't already) to get support for a wide variety of games and emulators.

You will most likely *not* need to tweak any of the default settings, however [this article](../Driver-Configuration-Utility-Explained.md) explains the configuration utility in great detail.

You can [show your gratitude towards the authors of the software](../../../Donations.md) by **making a donation**.

## Troubleshooting

If you are facing difficulties getting your devices to connect check out the following resources **before seeking support**:

- [Controller Compatibility](../About-Controller-Compatibility.md)
- [Frequently Asked Questions](../Frequently-Asked-Questions.md)

### Event Logs

The drivers log warnings and critical errors to the [Windows Event Log](https://www.digitalcitizen.life/how-start-event-viewer-windows-all-versions/) under `Windows Logs` / `System` from these event sources:

- `Nefarius Bluetooth PS Filter Service`
- `Nefarius BthPS3 Profile Driver`

![Event Viewer](images/event_viewer.png)

### Driver Traces

To get *even more* information out of the drivers [follow this article](../Debugging-the-drivers.md).
