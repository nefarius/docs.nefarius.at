# Inja Templates

The [Inja template engine](https://github.com/pantor/inja) is used for every field which involved specifying or resolving a file path on the local machine. This allows the user to specify any number of more or less complex lookups in dynamically building paths that might differ on each system.

For example hard-coding the absolute path `C:\Windows\System32\drivers\HidHide.sys` comes with some more or less obvious downsides; the users' Windows installation might not be located under the iconic `C:\` drive and the lookup would fail. Instead we can query for the system directory dynamically with a template like `{{ envar(windir) }}\System32\drivers\{{ product }}.sys` with the following data:

```json
"data": {
    "windir": "WINDIR",
    "product": "HidHide"
}
```

To fully understand the syntax and usage please [get familiar with the official tutorial first](https://github.com/pantor/inja#tutorial), then continue this article to learn the product-specific extensions.

## Extension functions

In addition to the [built-in functions](https://github.com/pantor/inja#functions), the following custom extensions are provided.

### `envar`

Expands/resolves an environment variable by name.

Parameter Pos. | Description | Mandatory
---|---|---
1 | The name of the environment variable to query. | Yes
2 | The optional fallback value to use if the variable couldn't be read or doesn't exist. | No

### `regval`

Queries a registry value.

Parameter Pos. | Description | Mandatory
---|---|---
1 | The [Alternate Registry View](https://learn.microsoft.com/en-us/windows/win32/winprog64/accessing-an-alternate-registry-view) to use if a 32-Bit updater process needs to read a 64-Bit key and vice versa. Only useful if the updater architecture differs from the installed product architecture (e.g. the product is a 32-Bit installation and the updater is a 64-Bit build). In most cases it should be avoided to mix architectures and simply use the value `Default`. Possible values are: <ul><li>`Default` - Doesn't alter default behaviour.</li><li>`WOW64_64KEY` - Access a 64-bit key from either a 32-bit or 64-bit application.</li><li>`WOW64_32KEY` - Access a 32-bit key from either a 32-bit or 64-bit application.</li></ul> | Yes
2 | The [hive](https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/windows-registry-advanced-users) to search in. Possible values are: <ul><li>`HKCU` for `HKEY_CURRENT_USER`</li><li>`HKLM` for `HKEY_LOCAL_MACHINE`</li><li>`HKCR` for `HKEY_CLASSES_ROOT`</li></ul> | Yes
3 | The sub-key path under the specified hive. For example `SOFTWARE\Nefarius Software Solutions e.U.\HidHide`. | Yes
4 | The value name to query. Type gets auto-detected. Supported value types are: <ul><li>`REG_BINARY` - Read as a byte array. Gets returned as a JSON array string.</li><li>`REG_DWORD` - A 32-bit number. Gets returned as a string.</li><li>`REG_EXPAND_SZ` - A null-terminated string that contains references to environment variables, for example, %PATH%. Gets returned with its environment variables expanded.</li><li>`REG_MULTI_SZ` - A sequence of null-terminated strings, terminated by an empty string (\0). Gets returned as a JSON array string.</li><li>`REG_QWORD` - A 64-bit number. Gets returned as a string.</li><li>`REG_SZ` - A null-terminated string.</li></ul> | Yes
5 | The fallback value to return on error, if provided. An empty string by default. | No

### `inival`

Reads a value from a section of an INI file.

Parameter Pos. | Description | Mandatory
---|---|---
1 | The path to the INI file to read. | Yes
2 | The section to search the key in. | Yes
3 | The key name to read. | Yes
4 | The fallback value to return on error, if provided. An empty string by default. | No

### `productBy`

Searches for an installed products' details based on provided regular expression.

Parameter Pos. | Description | Mandatory
---|---|---
1 | The Uninstall Registry value name (e.g. `DisplayName`, `Publisher`, ...) to query. | Yes
2 | The regular expression to apply to the queried value. | Yes

!!! example "Query and response example"
    The example query `{% set query=productBy(parameters.value, parameters.product) %}` with data  
    ```json
    "data": {
        "value": "Publisher",
        "product": "Blackmagic"
    }
    ```  
    will result in the following content of the `query` variable:
    ```json
    {
        "count": "5",
        "results": [
            {
                "displayName": "Fairlight Audio Accelerator Utility",
                "publisher": "Blackmagic Design",
                "displayVersion": "1.0.13",
                "installDate": "20211215",
                "installLocation": "C:\\Program Files\\Blackmagic Design\\DaVinci Resolve\\audio\\Fairlight Audio Accelerator\\",
                "publisher": "Blackmagic Design",
                "uninstallString": "\"C:\\Program Files\\Blackmagic Design\\DaVinci Resolve\\audio\\Fairlight Audio Accelerator\\unins000.exe\""
            },
            {
                "displayName": "DaVinci Resolve Keyboards",
                "publisher": "Blackmagic Design",
                "displayVersion": "1.0.0.0",
                "installDate": "20191118",
                "installLocation": "",
                "installSource": "C:\\Users\\nefar\\AppData\\Local\\Temp\\{0F99ED6C-B74F-4761-B400-1E60209F202C}\\",
                "language": "1033",
                "publisher": "Blackmagic Design",
                "uninstallString": "MsiExec.exe /X{04F776FB-37A2-4116-84F2-6CF3D731999D}"
            },
            {
                "displayName": "DaVinci Resolve Control Panels",
                "publisher": "Blackmagic Design",
                "displayVersion": "2.0.1.0",
                "installDate": "20211210",
                "installLocation": "",
                "installSource": "C:\\Users\\nefar\\AppData\\Local\\Temp\\{6B2CFC86-11E0-48D2-966E-54D9E47D1BBB}\\",
                "language": "1033",
                "publisher": "Blackmagic Design",
                "uninstallString": "MsiExec.exe /X{7667C543-084F-47F7-BC60-175FC25E9D6F}"
            },
            {
                "displayName": "DaVinci Resolve",
                "publisher": "Blackmagic Design",
                "displayVersion": "17.4.20009",
                "installDate": "20211215",
                "installLocation": "",
                "installSource": "C:\\Users\\nefar\\AppData\\Local\\Temp\\7zS41876E80\\",
                "language": "1033",
                "publisher": "Blackmagic Design",
                "uninstallString": "MsiExec.exe /X{D407791D-9F95-4731-89BB-1BE70CB8A25F}"
            },
            {
                "displayName": "Blackmagic RAW Common Components",
                "publisher": "Blackmagic Design",
                "displayVersion": "2.1",
                "installDate": "20210321",
                "installLocation": "",
                "installSource": "C:\\Users\\nefar\\AppData\\Local\\Temp\\{66175DB2-488F-4AEA-B383-442619210E33}\\",
                "language": "1033",
                "publisher": "Blackmagic Design",
                "uninstallString": "MsiExec.exe /I{FC105F36-D90B-4135-B954-F50CDCFACA3D}"
            }
        ]
    }
    ```
