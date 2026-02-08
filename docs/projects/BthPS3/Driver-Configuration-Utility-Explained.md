# Driver Configuration Utility Explained

The **BthPS3 Driver Configuration Tool** is a small, self-contained .NET application included with the installer. It lets you adjust how the drivers behave. You can find it by searching for it in the Start menu.

## Profile Driver Settings

These settings control the profile driver—the component that detects and connects controllers. Depending on which companion solutions you use (e.g. DsHidMini), you may need to change some of these for everything to work.

![Profile Driver Settings](../../images/BthPS3CfgUI_heAsEzf3Rj.png)

### Enable SIXAXIS™/DualShock™ 3 Support

!!! important "TL;DR"
    This must be **on** if you want your DS3 to work over Bluetooth.

PS3 peripherals do not report much identification data (e.g. Vendor ID, Product ID). The driver instead uses the **remote name** the device reports when connecting to decide the type of device. The driver ships with a set of known names that are matched to identify SIXAXIS-compatible devices. This is not perfect but works for most original and many third-party devices.

If this setting is enabled, the driver compares the remote name to that list and, on a match, connects the device as SIXAXIS-compatible. If it is disabled, detection is skipped and the connection is refused.

The following PowerShell snippet returns the currently configured names which identify a SIXAXIS-ish device:

!!! example "PowerShell"
    ```PowerShell
    Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\BthPS3\Parameters" -Name "SIXAXISSupportedNames" | Select-Object -ExpandProperty "SIXAXISSupportedNames"
    ```

You can edit or add names in the registry to try devices that report different names. The comparison is case-sensitive; names must match exactly.

### Enable PlayStation® Move Navigation Support

If ticked, the pre-configured list of remote device names will be used to attempt to identify and connect a Move Navigation compatible device. The process is skipped and the connection denied, if the setting is off.

The following PowerShell snippet returns the currently configured names which identify a Navigation-ish device:

!!! example "PowerShell"
    ```PowerShell
    Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\BthPS3\Parameters" -Name "NAVIGATIONSupportedNames" | Select-Object -ExpandProperty "NAVIGATIONSupportedNames"
    ```

### Enable PlayStation® Move Motion Support

If ticked, the pre-configured list of remote device names will be used to attempt to identify and connect a Move Motion compatible device. The process is skipped and the connection denied, if the setting is off.

The following PowerShell snippet returns the currently configured names which identify a Motion-ish device:

!!! example "PowerShell"
    ```PowerShell
    Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\BthPS3\Parameters" -Name "MOTIONSupportedNames" | Select-Object -ExpandProperty "MOTIONSupportedNames"
    ```

This setting is off by default to not conflict with the [PSMoveService](https://github.com/psmoveservice/PSMoveService) project.

### Enable Wireless Controller (DualShock™ 4) Support

If ticked, the pre-configured list of remote device names will be used to attempt to identify and connect a Wireless/DualShock 4 compatible device. The process is skipped and the connection denied, if the setting is off.

The following PowerShell snippet returns the currently configured names which identify a DualShock 4-ish device:

!!! example "PowerShell"
    ```PowerShell
    Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\BthPS3\Parameters" -Name "WIRELESSSupportedNames" | Select-Object -ExpandProperty "WIRELESSSupportedNames"
    ```

This setting is off by default to not conflict with the [DS4Windows](https://github.com/Ryochan7/DS4Windows) project.

### Automatically re-enable filter after grace period has passed

The profile driver can instruct the filter driver to enable or disable its patching (re-routing) capabilities if necessary. This is particularly useful if you want to connect a DualShock 4 the "traditional" way (pair and connect it in "PC mode" which needs no special drivers) which will accidentally be picked up by the profile driver due to the way the connection logic in the DS4 is designed. It might be undesired to connect a DS4 "through" BthPS3 since it works perfectly with stock drivers, so the profile driver will drop the connection, disable the filter for a specified amount of seconds, let the DS4 connect in "vanilla" mode and re-enable the patch again to continue supporting the other PS3 peripherals.

Leaving this on is the default behavior. If you turn it off, you need to control filter behavior yourself (see [Filter Driver Settings](#filter-driver-settings)).

### Re-enable filter after...

How long (in seconds) to wait before the filter turns back on. If you have trouble connecting a DS4 or other wireless controllers over Bluetooth, try increasing this value and powering the controller on again. If it still fails, see [Filter Driver Settings](#filter-driver-settings).

### Automatically disable filter on unsupported device arrival

If the driver cannot identify the remote device (unknown name or other connection issues), the profile driver can tell the filter to temporarily **disable** itself, restoring normal ("vanilla") Bluetooth stack behaviour. BthPS3 can sometimes interfere with other wireless controllers because of how PS3 peripherals work; this option helps avoid that. It is recommended to leave it enabled.

## Filter Driver Settings

The filter driver re-routes HID-related traffic to the profile driver so it can detect when a compatible PS3 peripheral is trying to connect. The settings below can be changed at any time.

![Filter Driver Settings](../../images/BthPS3CfgUI_sOGOHOlymb.png)

### Enable PSM patching

When **on**, the filter re-routes traffic so the profile driver can handle PS3 peripherals. When **off**, the Bluetooth stack behaves as if BthPS3 were not installed—other Bluetooth gaming devices may connect more easily, but PS3 peripherals will not work.

To use a DS3, DS4, and Xbox One controller at the same time:

1. Leave the filter **on**.
2. Connect the DS3 and wait until it is online.
3. Turn the filter **off**.
4. Connect the DS4 and Xbox Wireless devices.
5. Turn the filter **on** again if you need to connect more PS3 peripherals later.

## Danger Zone

!!! important "Use with care"
    Some companion solutions (e.g. Shibari or DsHidMini) require specific values here. Changing these incorrectly can cause instability. Read the descriptions carefully.

The Danger Zone contains advanced settings. Some companion solutions require a specific combination of these options; the table below summarises what is needed.

![Danger Zone](../../images/BthPS3CfgUI_xTFIBvuuAI.png)

### Expose PDO as RAW device to user-land

| Companion | Required state |
|---|---|
| Shibari | On |
| DsHidMini | Off |

When **on**, the profile driver’s child devices (PDOs) can be used without a dedicated driver and can be opened by user-mode applications (e.g. Shibari). HID Control and Interrupt channels can be used via the Windows API from any language. See [API Documentation](API-Documentation.md). This is useful for prototyping without writing kernel or user-mode driver code.

**Default:** On

### Hide PDO from Device Manager

When enabled, connected controller devices are hidden in Device Manager. You can still see them by enabling **View** → **Show hidden devices**. This does not change how the drivers work.

**Default:** Off

### Restrict PDO access to elevated users

When enabled, devices in RAW mode can only be enumerated and opened by elevated processes (run as Administrator or as a system service). Use this if a companion solution must run elevated.

**Default:** Off (any user can enumerate devices)

### Exclusive PDO access enforced

In RAW mode, multiple processes could open the same device. For game controllers this is undesirable: only one process should handle input and LED state, or you get split input and conflicting behaviour. This option enforces exclusive access.

**Recommendation:** Leave enabled unless you need multiple handles for a specific use case.

### PDO S0 Idle Timeout

After a PS3 peripheral receives its start packet, it keeps sending input to the host until it is turned off. That uses buffer memory that must be read by a driver or application. If nothing is reading the data, this setting disconnects the device after the configured idle time with no I/O.

**Recommendation:** Leave at the default unless you have a specific reason to change it.
