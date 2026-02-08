# BthPS3 Installed Successfully

Congratulations—BthPS3 is now installed.

## Next steps

You will probably want to install the **companion solution [DsHidMini](../../DsHidMini/index.md)** (if you have not already) for support in games and emulators.

You usually do **not** need to change the default settings. For details on the configuration tool, see the [Driver Configuration Utility](../Driver-Configuration-Utility-Explained.md).

You can [support the authors](../../../Donations.md) by making a donation.

## Troubleshooting

If you have trouble getting your devices to connect, check these resources **before asking for help**:

- [About controller compatibility](../About-Controller-Compatibility.md)
- [Frequently asked questions](../Frequently-Asked-Questions.md)

### Event logs

The drivers write warnings and critical errors to the [Windows Event Log](https://www.digitalcitizen.life/how-start-event-viewer-windows-all-versions/) under **Windows Logs** → **System**, from these sources:

- **Nefarius Bluetooth PS Filter Service**
- **Nefarius BthPS3 Profile Driver**

![Event Viewer](images/event_viewer.png)

### Driver traces

For more detailed driver output, see [Debugging the drivers](../Debugging-the-drivers.md).
