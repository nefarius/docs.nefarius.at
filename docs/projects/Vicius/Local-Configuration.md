# Local Configuration

The local configuration can **optionally** be provided by shipping a `.json` file alongside the updater executable and simply giving it the same name as the executable.

For example, having our updater called `nefarius_HidHide_Updater.exe` it will look for `nefarius_HidHide_Updater.json` within the same directory.

!!! warning "Can be disabled on build"
    The local configuration file is completely ignored if the updater has been built with  
    `NV_FLAGS_NO_CONFIG_FILE` set in `CustomizeMe.h`!

## Notable `shared` fields

The `shared` section accepts a number of fields that influence how the updater behaves and is presented. All are optional.

Field | Type | Description
---|---|---
`windowTitle` | `string` | Window title shown in the taskbar. Default: `"Nefarius' Updater"`.
`productName` | `string` | Product name shown in the UI (e.g. "Updates for **My Product** are available"). Default: `"Updater"`.
`detectionMethod` | `string` | The [product detection method](Product-Detection.md) to use.
`detection` | `object` | Parameters for the chosen detection method.
`installationErrorUrl` | `string` | URL opened in the browser when an installation fails, so the user can find further guidance.
`downloadLocation` | `object` | Custom download directory expressed as an [Inja template](Inja-Templates.md). Accepts `input` (template string) and optional `data` (template variables). Useful when the default temp directory is unsuitable.
`runAsTemporaryCopy` | `bool` | When `true` the updater copies itself to a temporary location before applying the ZIP-based update, so the updater file can be replaced. Useful for portable software distributed as a ZIP. See [ZIP Archives](ZIP-Archives.md).
`hideRemindButton` | `bool` | When `true` the "Remind me tomorrow" button is hidden from the update notification window, preventing the user from deferring the update.
`iconBase64` | `string` | Base64-encoded Windows `.ico` data. When set, the updater uses this icon for its window and taskbar entry instead of the built-in default.
`productBusyDetection` | `object` | When set, the update notification dialog is deferred until none of the configured processes are running. See [Product Busy Detection](#productbusydetection) below.
`signatureVerificationMode` | `string` | Controls whether the Authenticode signature of the downloaded setup is checked. Possible values: `Disabled`, `WhenPresent` (default), `Required`. See [Signature Verification](Signature-Verification.md).
`signaturePolicy` | `string` | Controls whether the signing certificate identity must match a configured pin once the Authenticode chain is valid. Possible values: `Relaxed` (default), `Strict`. See [Signature Verification](Signature-Verification.md).
`signatureStrategy` | `string` | When `signaturePolicy` is `Strict`, controls where the expected certificate identity comes from. Possible values: `FromUpdaterBinary` (default), `FromConfiguration`. See [Signature Verification](Signature-Verification.md).
`signatureConfig` | `object` | Explicit certificate pin fields used with the `FromConfiguration` strategy. See [Signature Verification](Signature-Verification.md) for available fields.

!!! example "Custom icon"
    Generate a base64 string from your `.ico` file (e.g. with PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes('icon.ico'))`) and embed it:

    ```json
    {
        "shared": {
            "iconBase64": "<base64-encoded .ico data>"
        }
    }
    ```

## `productBusyDetection`

When this optional object is present in the `shared` section, the updater waits for all configured processes to stop running before displaying the update notification dialog. This prevents the dialog from popping up while the user is actively working with the product being updated — a situation where an installation is typically not useful anyway because the product files are in use.

The wait loop is message-pumping rather than a blocking sleep, so the process exits cleanly on logoff or shutdown. If the product is still running after the maximum wait duration, **or** if a logoff/shutdown signal is received while waiting, the updater exits with code [`209`](Exit-Codes.md) and the next scheduled or logon invocation retries from scratch.

Field | Type | Description | Required
---|---|---|---
`imageNames` | `string[]` | Process image base names matched **case-insensitively** against the running process list, e.g. `["MyApp.exe"]`. The updater considers the product in use when **any** of these names matches. | No (but at least one of `imageNames` or `executablePaths` should be provided for the detection to be meaningful)
`executablePaths` | `string[]` | Optional list of absolute paths (or [Inja templates](Inja-Templates.md)) matched against the full image path of running processes. Useful when multiple unrelated products share the same executable base name. | No
`pollIntervalSeconds` | `int` | Seconds between successive in-use re-checks. Default: `60`. Minimum enforced by the agent: `5`. | No
`maxWaitMinutes` | `int` | Maximum minutes to wait before giving up. Default: `180` (3 hours). The agent hard-clamps this value to `180` regardless of what is configured, so the updater process can never run indefinitely. Set to `0` to check once and exit immediately if the product is in use. | No

!!! tip "The feature is opt-in"
    Deployments that do not set `productBusyDetection` are entirely unaffected. The behavior of the updater is unchanged unless this object is present.

!!! note "Can be overridden on the command line"
    Passing [`--ignore-product-in-use`](Command-Line-Arguments.md#--ignore-product-in-use) bypasses the gate and shows the dialog immediately regardless of this setting.

!!! note "Interaction with `--terminate-process-before-update`"
    The product-busy gate is automatically skipped when [`--terminate-process-before-update`](Command-Line-Arguments.md#-terminate-process-before-update-handle) is active, because that mode is designed to kill the product before installation and waiting would be contradictory.

!!! example "Defer while HidHide is running"

    ```json
    {
        "shared": {
            "productBusyDetection": {
                "imageNames": ["HidHide.exe"],
                "pollIntervalSeconds": 60,
                "maxWaitMinutes": 180
            }
        }
    }
    ```

!!! example "Match by full path using an Inja template"

    ```json
    {
        "shared": {
            "productBusyDetection": {
                "imageNames": ["MyApp.exe"],
                "executablePaths": ["{{ envar(\"ProgramFiles\") }}\\Contoso\\MyApp\\MyApp.exe"],
                "pollIntervalSeconds": 30
            }
        }
    }
    ```

    Use the `envar(name)` callback to read environment variables inside inja templates. The `env[name]` bracket syntax is not available in this context. See [Inja Templates](Inja-Templates.md) for the full list of available callbacks.

## Notable `instance` fields

The `instance` section configures the updater's own behavior (server URL, network settings, etc.). All fields are optional unless stated otherwise.

Field | Type | Description
---|---|---
`serverUrlTemplate` | `string` | The URL or URL template used to fetch the remote configuration. `{}` is replaced with `manufacturer/product` (or `manufacturer/product/channel` when a channel is set). See [Server Discovery](Server-Discovery.md).
`fallbackServerUrlTemplates` | `string[]` | Additional URLs tried in order if the primary `serverUrlTemplate` request fails.
`filenameRegex` | `string` | Regular expression used to extract the `manufacturer` and `product` from the updater executable name. Default: `^(\w+)_(\w+)_Updater.*?`. Override this if your executable uses a different naming convention.
`channel` | `string` | Update channel name inserted into the server URL template as the third path segment. Can also be supplied via [`--channel`](Command-Line-Arguments.md#--channel-value) on the command line.
`authority` | `string` | Controls which configuration source wins for overlapping `shared` fields. Possible values: `Remote` (default), `Local`. See [Authority](#authority-field) below.
`network` | `object` | Network and proxy settings. See the table below.

### `network` fields

Field | Type | Description
---|---|---
`proxyMode` | `string` | How the updater selects a proxy. Possible values: `System` (default — use the system proxy), `None` (direct connection, no proxy), `Custom` (use `proxyUrl`).
`proxyUrl` | `string` | Explicit HTTP proxy URL (e.g. `http://proxy.corp:8080`). Only used when `proxyMode` is `Custom`.
`dohUrl` | `string` | DNS-over-HTTPS resolver URL. When set, DNS lookups use this resolver instead of the system default.
`ipFamily` | `string` | IP version preference. Possible values: `Any` (default), `IPv4`, `IPv6`.
`pinnedHosts` | `object[]` | List of host-pin entries for certificate pinning on specific hosts.

## `Authority` field

By default the update server holds *a lot* of power over the instance configuration. If you want shared values only to be read and applied from the provided local configuration you can set it to `Local`:

```json
{
    "instance": {
        "authority": "Local" // the default value is "Remote", if omitted
    }
}
```

Now only values in the local `shared` section will apply and server-provided fields of the same name will be ignored.

!!! warning "Carefully consider your design before altering this"
    If you set the authority to `Local`, you will not be able to push corrections of the affected values later on the server-side. If you made a mistake in the configuration file shipped to the end-users, it will remain stuck until you e.g. publish an update that also delivers a new, corrected configuration file.

## Examples

### Example `nefarius_HidHide_Updater.json` file

```json
{
   "instance": {
      "serverUrlTemplate": "https://vicius.api.nefarius.systems/api/nefarius/HidHide/updates.json",
      "authority": "Remote"
   },
   "shared": {
      "windowTitle": "HidHide Updater",
      "productName": "Nefarius HidHide",
      "detectionMethod": "RegistryValue",
      "detection": {
         "hive": "HKLM",
         "key": "SOFTWARE\\Nefarius Software Solutions e.U.\\HidHide",
         "value": "Version"
      }
   }
}
```
