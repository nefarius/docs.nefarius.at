# Local Configuration

The local configuration can **optionally** be provided by shipping a `.json` file alongside the updater executable and simply giving it the same name as the executable.

For example, having our updater called `nefarius_HidHide_Updater.exe` it will look for `nefarius_HidHide_Updater.json` within the same directory.

!!! warning "Can be disabled on build"
    The local configuration file is completely ignored if the updater has been built with  
    `NV_FLAGS_NO_CONFIG_FILE` set in `CustomizeMe.h`!

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
