# Local Configuration

The local configuration can **optionally** be provided by shipping a `.json` file alongside the updater executable and simply giving it the same name as the executable.

For example, having our updater called `nefarius_HidHide_Updater.exe` it will look for `nefarius_HidHide_Updater.json` within the same directory.

!!! warning "Can be disabled on build"
    The local configuration file is completely ignored if the updater has been built with  
    `NV_FLAGS_NO_CONFIG_FILE` set in `CustomizeMe.h`!

## Example `nefarius_HidHide_Updater.json` file

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
