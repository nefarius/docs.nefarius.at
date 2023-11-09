# Inja Templates

To be continued...

## Extension functions

### `envar`

Parameter Pos. | Description | Mandatory
---|---|---
1 | The name of the environment variable to query. | Yes
2 | The optional fallback value to use if the variable couldn't be read or doesn't exist. | No

### `regval`

Parameter Pos. | Description | Mandatory
---|---|---
1 | The [Alternate Registry View](https://learn.microsoft.com/en-us/windows/win32/winprog64/accessing-an-alternate-registry-view) to use if a 32-Bit updater process needs to read a 64-Bit key and vice versa. Only useful if the updater architecture differs from the installed product architecture (e.g. the product is a 32-Bit installation and the updater is a 64-Bit build). In most cases it should be avoided to mix architectures and simply use the value `Default`. Possible values are <ul><li>`Default` - Doesn't alter default behaviour.</li><li>`WOW64_64KEY` - Access a 64-bit key from either a 32-bit or 64-bit application.</li><li>`WOW64_32KEY` - Access a 32-bit key from either a 32-bit or 64-bit application.</li></ul> | Yes
2 | The [hive](https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/windows-registry-advanced-users) to search in. Possible values are <ul><li>`HKCU` for `HKEY_CURRENT_USER`</li><li>`HKLM` for `HKEY_LOCAL_MACHINE`</li><li>`HKCR` for `HKEY_CLASSES_ROOT`</li></ul> | Yes
3 | The sub-key path under the specified hive. For example `SOFTWARE\Nefarius Software Solutions e.U.\HidHide`. | Yes
4 | The value to query. Type gets auto-detected. Supported value types are <ul><li>`REG_BINARY` - Read as a byte array. Gets returned as a JSON array string.</li><li>`REG_DWORD` - A 32-bit number.</li><li>`REG_EXPAND_SZ` - A null-terminated string that contains references to environment variables, for example, %PATH%. Gets returned with its environment variables expanded.</li><li>`REG_MULTI_SZ` - A sequence of null-terminated strings, terminated by an empty string (\0). Gets returned as a JSON array string.</li><li>`REG_QWORD` - A 64-bit number.</li><li>`REG_SZ` - A null-terminated string.</li></ul> | Yes
