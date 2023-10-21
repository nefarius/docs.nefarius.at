# Server Discovery

The single most important setting that *at least* needs to be customized is the URL to your web server which delivers the update configuration file. The following possibilities are offered to you to choose from.

## Configuration options

### Make your own custom build

Check out the projects source code, edit the `NV_API_URL_TEMPLATE` value in `CustomizeMe.h` and build your very own copy of the updater. Done!

!!! note "Consider signing your executable"
    Consider signing the resulting binary with your (company's) code signing certificate.

### Edit the string table resource

If you wish to both avoid compiling your own binary and shipping a configuration file, you can use [Resource Hacker](https://angusj.com/resourcehacker/) on the updater executable and edit the string table entry `105` as seen below:

![ResourceHacker_LYM3c3MEtm.png](images/ResourceHacker_LYM3c3MEtm.png)

!!! warning "Doing so will break the executable signature"
    If you use this method, beware that this will invalidate the signature of the executable.  
    Consider re-signing the resulting binary, if possible or avoid this method altogether.
