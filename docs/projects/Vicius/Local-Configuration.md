# Local Configuration

The local configuration can **optionally** be provided by shipping a `.json` file alongside the updater executable and simply giving it the same name as the executable.

For example, having our updater called `nefarius_HidHide_Updater.exe` it will look for `nefarius_HidHide_Updater.json` within the same directory.

!!! warning "Can be disabled on build"
    The local configuration file is completely ignored if the updater has been built with  
    `NV_FLAGS_NO_CONFIG_FILE` set in `CustomizeMe.h`!

## Notable `shared` fields

The `shared` section accepts a number of fields that influence how the updater behaves and is presented. The most commonly needed ones are listed here; all are optional.

Field | Type | Description
---|---|---
`windowTitle` | `string` | Window title shown in the taskbar.
`productName` | `string` | Product name shown in the UI (e.g. "Updates for **My Product** are available").
`detectionMethod` | `string` | The [product detection method](Product-Detection.md) to use.
`detection` | `object` | Parameters for the chosen detection method.
`installationErrorUrl` | `string` | URL opened in the browser when an installation fails, so the user can find further guidance.
`downloadLocation` | `object` | Custom download directory expressed as an [Inja template](Inja-Templates.md). Accepts `input` (template string) and optional `data` (template variables). Useful when the default temp directory is unsuitable.
`runAsTemporaryCopy` | `bool` | When `true` the updater copies itself to a temporary location before applying the ZIP-based update, so the updater file can be replaced. Useful for portable software distributed as a ZIP. See [ZIP Archives](ZIP-Archives.md).
`hideRemindButton` | `bool` | When `true` the "Remind me tomorrow" button is hidden from the update notification window, preventing the user from deferring the update.
`iconBase64` | `string` | Base64-encoded Windows `.ico` data. When set, the updater uses this icon for its window and taskbar entry instead of the built-in default.

!!! example "Custom icon"
    Generate a base64 string from your `.ico` file (e.g. with PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes('icon.ico'))`) and embed it:

    ```json
    {
        "shared": {
            "iconBase64": "AAABAAEAEBAAAAEAIAAoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAA..."
        }
    }
    ```

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
