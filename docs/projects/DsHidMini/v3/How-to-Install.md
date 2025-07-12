# How to Install/Remove

!!! danger highlight "DsHidMini V3 BETA installation page!"
    Version 3 is still in BETA. Although all of our tests indicate things are working smoothly keep in mind that you may encounter unknown issues or features that are missing or yet to be implemented.

    Make sure to check the [intro page for the V3 Beta](../) before continuing!

## Installation

!!! danger highlight "STOP trying to use DsHidMini with random controllers"
    Only and **only** this controller (Sony DualShock 3 a.k.a. PS3 Gamepad) is supported:  
    ![ds3](images/dualshock-3-resized.png)  
    Do NOT contact support for any other device, **it will not work**, no matter how many times you ask!

No matter what software you may have preinstalled, this step is always the same 😀

### Version 3.x.x

- **If you want Bluetooth support** you need to [install BthPS3 first](https://github.com/nefarius/BthPS3/releases/latest) (optional for USB)

For installation of the Version 3 BETA driver and tools, follow along:

1. Download and install **DsHidMini Version 3 Driver** by downloading the [latest release marked as Pre-release](https://github.com/nefarius/DsHidMini/releases) or any version labeled v3.x.x
    - For the setup to work correctly **Windows UAC needs to be enabled**. If in doubt, the following page has instructions on how to check its status: [link here](https://articulate.com/support/article/how-to-turn-user-account-control-on-or-off-in-windows-10)
2. Download and execute the [DsHidMini **ControlApp**](https://buildbot.nefarius.at/builds/DsHidMini/latest/bin/ControlApp.exe), a companion application for configuring DsHidMini controllers
    - You don't need to have the ControlApp open for DsHidMini to work. Only use it to monitor and configure DsHidMini controllers, so keep it in a convenient location for easy access
    - ControlApp requires the **.NET Desktop Runtime 8** to be able to run. To check whether you already have it, simply try opening the ControlApp — It will either open normally or prompt you to install [.NET Desktop Runtime 8](https://dotnet.microsoft.com/en-us/download/dotnet/8.0)
3. Have fun testing!
    - By now if you plug in your controller (or reboot the machine) chances are high that everything already works as expected. If it doesn't, worry not, [read on here](#troubleshooting)!
    - Under default settings controllers should behave as if they were an "Xbox" controller (XInput Device)

![controlapp-preview-image.jpg](images/controlapp-preview-image.jpg)

## Updating

If you want to update, simply [follow the same installation steps](#installation) and overwrite any existing files. Reboot your machine to be extra safe if it didn't work right away.

## Removal

1. The main Beta v3 driver can be removed by just uninstalling `Nefarius DsHidMini Driver` in Windows' Apps & features
2. BthPS3 can also be uninstalled the same way as above via Apps & Features
3. The ControlApp companion application isn’t installed in the traditional sense and can be deleted like any other file

![ApplicationFrameHost_nFtPcyobyf.png](images/ApplicationFrameHost_nFtPcyobyf.png)

After that, DsHidMini should be fully gone from your computer 😥

## Troubleshooting

<!--
### Verifying if the controller is loading the correct driver

The driver can't do anything if it is not being used, so to check this:

- Connect your controller **by USB** cable
- Open Device Manager by pressing ++win+x++ and select it from the menu
- Search for and expand the category `Nefarius HID Devices`, your controller should appear there. Double click on it to check the driver status:  
![DsHidMini_DeviceManager](images/DsHidMini_Correctly_Loaded.png)

If the device appears there but the driver status indicates some error (e.g. `This device cannot start (Error Code 10)`) try pressing the `Reset` button on the back of your controller and then reconnecting it. Rebooting your computer is also worth a shot.

If the controller does not appear under `Nefarius HID Devices` or if this section doesn't exist at all, you probably have another driver taking priority over DsHidMini. To solve this try [uninstalling](#removal) and then [installing again](#installation) DsHidMini version 3.
-->
### Removing conflicting drivers

!!! warning highlight "Always try reinstalling DsHidMini V3 first!"
    You don't need to follow this section manually, just try reinstalling DsHidMini V3 as its installer verifies and removes drivers known to conflict with it.

??? info highlight "Legacy section on conflicting drivers removal (click to expand)"

    We need to first determine if any other conflicting device driver is present on the system and remove it so DsHidMini can take over that job. The steps outlined here may or may not be applicable to your system, it entirely depends on your past 😜 and the stuff you potentially installed. Worry not though, together we shall succeed ✨

    **ScpToolkit**

    If you had ScpToolkit installed, you need to purge every remains from your machine. [Follow this comprehensive removal guide](../../ScpToolkit/ScpToolkit-Removal-Guide.md).

    **Official Sony driver**

    If you have/had PS Now installed, chances are high you have the official Sony `sixaxis.sys` on your system. [Follow this procedure to remove it](../v2/SIXAXIS.SYS-to-DsHidMini-Guide.md).

    **FireShock**

    If you've used [Shibari](https://github.com/nefarius/Shibari) before you probably have FireShock installed. [Follow this procedure to remove it](../../FireShock/Removal-Guide.md).

### DSHMC.exe not detecting DsHidMini V3 controllers

DsHidMini V3 requires the new ControlApp companion tool. Check the [installation section](#installation) on how to get it.

### Controller does not connect by Bluetooth

This section is under construction. Meanwhile consult all the other existing FAQ articles on our various project pages.
