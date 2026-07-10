# Product Detection

Besides the [Server Discovery](Server-Discovery.md) the 2nd most important mandatory configuration block is how the updater can detect the local product it governs and how to determine if it is outdated or not. These settings can be provided either by the [local](Local-Configuration.md) or [remote](Remote-Configuration.md) configuration. The following detection mechanisms are currently implemented.

## Detection methods

### `RegistryValue`

[![Badge](https://img.shields.io/badge/Show%20example-ff6600)](https://vicius.api.nefarius.systems/api/contoso/RegistryValue/updates.json)

The product version is queried from a Registry location.

The value to query must be a string of of type [`REG_SZ`](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry-value-types).

Field | Description | Mandatory
---|---|---
`view` | The [Alternate Registry View](https://learn.microsoft.com/en-us/windows/win32/winprog64/accessing-an-alternate-registry-view) to use if a 32-Bit updater process needs to read a 64-Bit key and vice versa. Only useful if the updater architecture differs from the installed product architecture (e.g. the product is a 32-Bit installation and the updater is a 64-Bit build). In most cases it should be avoided to mix architectures and simply use the value `Default`. Possible values are: <ul><li>`Default` - Doesn't alter default behaviour. **(Default if omitted)**</li><li>`WOW64_64KEY` - Access a 64-bit key from either a 32-bit or 64-bit application.</li><li>`WOW64_32KEY` - Access a 32-bit key from either a 32-bit or 64-bit application.</li></ul> | No
`hive` | The [hive](https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/windows-registry-advanced-users) to search in. Possible values are: <ul><li>`HKCU` for `HKEY_CURRENT_USER`</li><li>`HKLM` for `HKEY_LOCAL_MACHINE`</li><li>`HKCR` for `HKEY_CLASSES_ROOT`</li></ul> | Yes
`key` | The sub-key path under the specified hive. For example `SOFTWARE\Nefarius Software Solutions e.U.\HidHide`. | Yes
`value` | The `REG_SZ` (string) value to read. For example `Version`. | Yes

### `FileVersion`

[![Badge](https://img.shields.io/badge/Show%20example-ff6600)](https://vicius.api.nefarius.systems/api/contoso/FileVersion/updates.json)

Reads the [VERSIONINFO resource](https://learn.microsoft.com/en-us/windows/win32/menurc/versioninfo-resource) of a given file where the `FileVersion` (or `ProductVersion`) will get compared to the release's `detectionVersion` field provided by the server.

Field | Description | Mandatory
---|---|---
`input` | The absolute path **or** the [inja template](Inja-Templates.md) resolve the path to the client file to read. | Yes
`statement` | The version resource statement to read. Possible values are: <ul><li>`FILEVERSION` - The binary version number for the file.</li><li>`PRODUCTVERSION` - The binary version number for the product with which the file is distributed. This is the default, if omitted.</li></ul> | No
`data` | A dictionary/map of the data used in the template. | No

### `FileSize`

[![Badge](https://img.shields.io/badge/Show%20example-ff6600)](https://vicius.api.nefarius.systems/api/contoso/FileSize/updates.json)

Reads a file's size (in bytes) and compares it to the release's `detectionSize` field provided by the server. If the local size doesn't match the release size the product is flagged as outdated.

Field | Description | Mandatory
---|---|---
`input` | The absolute path **or** the [inja template](Inja-Templates.md) resolve the path to the client file to read. | Yes
`data` | A dictionary/map of the data used in the template. | No

### `FileChecksum`

[![Badge](https://img.shields.io/badge/Show%20example-ff6600)](https://vicius.api.nefarius.systems/api/contoso/FileChecksum/updates.json)

Computes a file's hash/checksum via the algorithm specified in the release and compares it to the `detectionChecksum.checksum` field. If the locally computed hash doesn't match the release hash (case-insensitive) the product is flagged as outdated.

Field | Description | Mandatory
---|---|---
`input` | The absolute path **or** the [inja template](Inja-Templates.md) resolve the path to the client file to read. | Yes
`data` | A dictionary/map of the data used in the template. | No

### `CustomExpression`

[![Badge](https://img.shields.io/badge/Show%20example-ff6600)](https://vicius.api.nefarius.systems/api/contoso/CustomExpression/updates.json)

Evaluates a custom [inja expression](Inja-Templates.md) to determine the state.

Returning `true` indicates the product is considered outdated, return `false` otherwise.

Field | Description | Mandatory
---|---|---
`input` | The [inja template](Inja-Templates.md) to evaluate on the client. | Yes
`data` | A dictionary/map of the data used in the template. | No

!!! important "Access to data in your expression"
    You can use three pre-defined variables in your template/expression:  
    - `merged` holds the shared configuration state of the client.  
    - `remote` holds the server response.  
    - `parameters` holds the contents of the `data` field from the **detection configuration** (i.e. the `data` key in the same object as `input`). Depending on the active `authority` setting, this may come from the local configuration file or from the server-provided detection config. It is not unconditionally "what the server provided".

    In addition, all [Inja template callbacks](Inja-Templates.md) (`envar`, `regval`, `inival`, `productBy`, `versionEq`, `versionGt`, `versionLt`, `exists`, `log`) are available inside the expression.

### `FixedVersion`

[![Badge](https://img.shields.io/badge/Show%20example-ff6600)](https://vicius.api.nefarius.systems/api/contoso/FixedVersion/updates.json)

Overrides the detected version with a fixed version string.

Field | Description | Mandatory
---|---|---
`version` | The version string. | Yes

## Release-side detection fields

Some detection methods compare a locally detected value against a reference provided on the **release object** in the [remote configuration](Remote-Configuration.md), rather than (or in addition to) the detection config itself.

Field | Used by | Description
---|---|---
`detectionVersion` | `RegistryValue`, `FileVersion`, `FixedVersion` | The expected version string for this release. If omitted, the release's `version` field is used as the fallback.
`detectionSize` | `FileSize` | The expected file size in bytes for this release.
`detectionChecksum` | `FileChecksum` | A [`ChecksumParameters`](Download-Integrity.md) object (`checksum` + `checksumAlg`) specifying the expected hash of the locally installed file for this release.

## Command-line overrides

Two CLI flags bypass whatever detection method is configured:

Flag | Effect
---|---
[`--local-version <version>`](Command-Line-Arguments.md#--local-version-version) | Overrides the detected local version only when no detection method is configured in either the local or remote configuration.
[`--force-local-version <version>`](Command-Line-Arguments.md#--force-local-version-version) | Unconditionally overrides the detected version, ignoring any detection method in local or remote configuration.
