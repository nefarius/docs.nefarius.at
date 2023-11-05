# Server Discovery

The single most important setting that *at least* needs to be customized is the URL to your web server which delivers the update configuration file. The following possibilities are offered to you to choose from.

## Configuration options

### Make your own custom build

Check out the projects source code, edit the `NV_API_URL_TEMPLATE` value in `CustomizeMe.h` and build your very own copy of the updater. Done!

!!! note "Consider signing your executable"
    Consider signing the resulting binary with your (company's) code signing certificate.

### Provide and ship a configuration file

Assuming your final updater executable name being `nefarius_HidHide_Updater.exe` you can create and package a JSON file called `nefarius_HidHide_Updater.json` to be delivered alongside your product setup. As long as the file contents are valid JSON and the name matches the updater executable, that's all you need to do!

!!! example "Minimal nefarius_HidHide_Updater.json example"
    ```json
    {
        "instance": {
            "serverUrlTemplate": "https://vicius.api.nefarius.systems/api/example/updates.json"
        }
    }
    ```

!!! warning "Protect the JSON file properly"
    Make sure to deliver both the executable and the configuration file to a location on the target machine that is not writable to non-elevated users (e.g. some sub-directory of `Program Files` or similar).  
    Bear in mind that any other (malicious) process running in the user context can edit the configuration file if you place the updater in e.g. `%LOCALAPPDATA%` folder.

### Edit the string table resource

!!! warning "Can be disabled during build"
    This method will **not work** if the updater binary is built with  
    `NV_FLAGS_NO_SERVER_URL_RESOURCE` set in `CustomizeMe.h`!

If you wish to both avoid compiling your own binary and shipping a configuration file, you can use [Resource Hacker](https://angusj.com/resourcehacker/) on the updater executable and edit the string table entry `105` as seen below:

![ResourceHacker_LYM3c3MEtm.png](images/ResourceHacker_LYM3c3MEtm.png)

!!! warning "Doing so will break the executable signature"
    If you use this method, beware that this will invalidate the signature of the executable.  
    Consider re-signing the resulting binary, if possible or avoid this method altogether.
