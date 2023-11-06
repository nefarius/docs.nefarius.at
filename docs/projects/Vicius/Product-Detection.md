# Product Detection

Besides the [Server Discovery](Server-Discovery.md) then 2nd most important mandatory configuration block is how the updater can detect the local product it governs and how to determine it is outdated or not. These settings can be provided either by the [local](Local-Configuration.md) or [remote](Remote-Configuration.md) configuration. The following detection mechanisms are currently implemented.

## `RegistryValue`

Field | Description | Mandatory
---|---|---
`view` | The [Alternate Registry View](https://learn.microsoft.com/en-us/windows/win32/winprog64/accessing-an-alternate-registry-view) to use if a 32-Bit updater process needs to read a 64-Bit key and vice versa. Only useful if the updater architecture differs from the installed product architecture (e.g. the product is a 32-Bit installation and the updater is a 64-Bit build). In most cases it should be avoided to mix architectures and simply use the value `Default`. | Yes
`hive` | The hive to search in. Possible values are <ul><li>`HKCU`</li><li>`HKLM`</li><li>`HKCR`</li></ul>
`key` | |
`value` | |

## `FileVersion`

## `FileSize`

## `FileChecksum`
