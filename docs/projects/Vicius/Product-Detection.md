# Product Detection

Besides the [Server Discovery](Server-Discovery.md) the 2nd most important mandatory configuration block is how the updater can detect the local product it governs and how to determine if it is outdated or not. These settings can be provided either by the [local](Local-Configuration.md) or [remote](Remote-Configuration.md) configuration. The following detection mechanisms are currently implemented.

## Detection methods

### `RegistryValue`

The product version is queried from a Registry location.

The value to query must be a string of of type [`REG_SZ`](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry-value-types).

Field | Description | Mandatory
---|---|---
`view` | The [Alternate Registry View](https://learn.microsoft.com/en-us/windows/win32/winprog64/accessing-an-alternate-registry-view) to use if a 32-Bit updater process needs to read a 64-Bit key and vice versa. Only useful if the updater architecture differs from the installed product architecture (e.g. the product is a 32-Bit installation and the updater is a 64-Bit build). In most cases it should be avoided to mix architectures and simply use the value `Default`. Possible values are <ul><li>`Default` - Doesn't alter default behaviour.</li><li>`WOW64_64KEY` - Access a 64-bit key from either a 32-bit or 64-bit application.</li><li>`WOW64_32KEY` - Access a 32-bit key from either a 32-bit or 64-bit application.</li></ul> | Yes
`hive` | The [hive](https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/windows-registry-advanced-users) to search in. Possible values are <ul><li>`HKCU` for `HKEY_CURRENT_USER`</li><li>`HKLM` for `HKEY_LOCAL_MACHINE`</li><li>`HKCR` for `HKEY_CLASSES_ROOT`</li></ul> | Yes
`key` | The sub-key path under the specified hive. For example `SOFTWARE\Nefarius Software Solutions e.U.\HidHide`. | Yes
`value` | The `REG_SZ` (string) value to read. For example `Version`. | Yes

### `FileVersion`

Reads the [VERSIONINFO resource](https://learn.microsoft.com/en-us/windows/win32/menurc/versioninfo-resource) of a given file where the `FileVersion` (or `ProductVersion`) will get compared to the release's `detectionVersion` field provided by the server.

Field | Description | Mandatory
---|---|---
`input` | The absolute path **or** the inja template resolve the path to the client file to read. | Yes
`statement` | The version resource statement to read. Possible values are <ul><li>`FILEVERSION` - The binary version number for the file.</li><li>`PRODUCTVERSION` - The binary version number for the product with which the file is distributed. This is the default, if omitted.</li></ul> | No
`data` | A dictionary/map of the data used in the template. | No

### `FileSize`

To be continued...

### `FileChecksum`

To be continued...
