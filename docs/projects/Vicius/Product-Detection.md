# Product Detection

Besides the [Server Discovery](Server-Discovery.md) the 2nd most important mandatory configuration block is how the updater can detect the local product it governs and how to determine if it is outdated or not. These settings can be provided either by the [local](Local-Configuration.md) or [remote](Remote-Configuration.md) configuration. The following detection mechanisms are currently implemented.

## Detection methods

### `RegistryValue`

Field | Description | Mandatory
---|---|---
`view` | The [Alternate Registry View](https://learn.microsoft.com/en-us/windows/win32/winprog64/accessing-an-alternate-registry-view) to use if a 32-Bit updater process needs to read a 64-Bit key and vice versa. Only useful if the updater architecture differs from the installed product architecture (e.g. the product is a 32-Bit installation and the updater is a 64-Bit build). In most cases it should be avoided to mix architectures and simply use the value `Default`. Possible values are <ul><li>`Default`</li><li>`WOW64_64KEY` - Access a 64-bit key from either a 32-bit or 64-bit application.</li><li>`WOW64_32KEY` - Access a 32-bit key from either a 32-bit or 64-bit application.</li></ul> | Yes
`hive` | The [hive](https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/windows-registry-advanced-users) to search in. Possible values are <ul><li>`HKCU` for `HKEY_CURRENT_USER`</li><li>`HKLM` for `HKEY_LOCAL_MACHINE`</li><li>`HKCR` for `HKEY_CLASSES_ROOT`</li></ul> | Yes
`key` | The sub-key path under the specified hive. For example `SOFTWARE\Nefarius Software Solutions e.U.\HidHide`. | Yes
`value` | The `REG_SZ` (string) value to read. For example `Version`. | Yes

### `FileVersion`

Field | Description | Mandatory
---|---|---
`path` | The absolute path to a local file with a [VERSIONINFO resource](https://learn.microsoft.com/en-us/windows/win32/menurc/versioninfo-resource) where the `ProductVersion` will get compared to the release versions provided by the server. | Yes

### `FileSize`

To be continued...

### `FileChecksum`

To be continued...
