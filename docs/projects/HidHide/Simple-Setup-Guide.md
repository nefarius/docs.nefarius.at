# Simple setup guide

!!! important "HidHide is only supported on 64 bits Windows 10 as for the day this article was written"

## What is HidHide

HidHide is a filter driver than can "hide" Gamepads/joysticks devices, ensuring Windows and other applications stop detecting it as a game controller and allowing only chosen applications to see them. Specially useful when the user is remapping a real controller into an emulated one.

![BeforeAfterHidHide](images/BeforeAfterHidHide.png)

## Why one might need it

Imagine the following scenario: you have a generic gamepad that you want to _"convert"_ into a __XInput Device__ (a Xbox 360 controller) or DualShock 4, since most games are already pre-configured to these controllers, or maybe your game doesn't even detect your generic one as it is. So you start using a remapping program ( [x360ce](https://www.x360ce.com/) / [XOutput](https://github.com/csutorasa/XOutput) / [UCR](https://github.com/Snoothy/UCR) / etc ) to do so.

This put you in a problematic situation: you don't end-up ___just___ with the emulated controller that you want to use. No no, you end-up with 2 controllers: the real and the emulated one.

If the games you are playing don't even detect your real controller, then all good. The issue starts when the game detects both real and emulated controllers while you only want it to recognize the latter. Since most games auto-detect controllers, the game will think there are 2 separate controllers connected, leading to the famous Double-Input and mis-input issue. Examples:

- Rocket league will start 2 player mode randomly
- Blasphemous will switch randomly between generic and XInput/DS4 button icons
- Need for Speed: Most Wanted (2012) will keep warning the player an unknown device needs to be setup, interfering with gameplay

This issue can be solved by using HidHide to:

- Hide the real controller
- Only allow the remapping tool of your choice to see the controller, since it needs to pick its input to translate them to the emulated one 

## Verifying if HidGuardian is installed and uninstalling it

!!! important "HidHide and HidGuardian MUST NOT be together on the same system"
    HidHide is HidGuardian's successor and both have the same function. Having the two installed simultaneously can cause confusion at best and actual issues at worst.

HidGuardian's installer utility can check if it's installed and correctly uninstall it in case it is, so that's what we are going to use:

- [Download and extract this archive](https://drive.google.com/file/d/1PNL3uv_4KektN00S9fm61djypSQ-3HED/view?usp=sharing)
- Inside the extracted folder, run HidGuardianInstaller.exe
- Check in the text log if HidGuardian is installed. If it is not, you can close the utility and move on to the next section

![UninstallHG](images/uninstall_hidguardian.png)

- If HidGuardian is installed, click on the "Uninstall" button
- Wait until the utility finishes uninstalling HidGuardian, keep and eye on the text log to know what its status
- After the tool finishes uninstalling HidGuardian, close it then reboot your PC

## Setting up HidHide (quick guide)

!!! important "Attention!"
    This section is for users who know more or less what they are doing. If you want a more detailed, step-by-step guide, jump to the next section.

- Download the [Latest release of HidHide](https://github.com/nefarius/HidHide/releases) (It should be a file called HidHideMSI.msi). Remember to install its prerequisites as written on the page
- After installation, reboot your computer
- Open the `HidHide Configuration Client` in the start menu
- On the `Applications` tab, add the applications that should be able to see the devices even when they are hidden
- On the `Devices` tab mark the controllers you want to be hidden (a red lock should appear), then mark the `Enable device hiding` Checkbox
- Reconnect your controllers to make the changes effective

DONE. Be happy. Still, be sure to give a read on the last sections of this article.

## Setting up HidHide (step-by-step guide)

### Installing HidHide

- Install [HidHide's prerequisites](https://support.microsoft.com/en-us/topic/the-latest-supported-visual-c-downloads-2647da03-1eea-4433-9aff-95f26a218cc0) according to your [Windows 10 version](../../research/How-to-check-architecture.md)
![VisualCpp](images/HidHide_VisualCpp.png)
- Download the [Latest release of HidHide](https://github.com/nefarius/HidHide/releases) (it should be a file called `HidHideMSI.msi`)
- Open the downloaded file and install HidHide as instructed at default settings (just click `Next` until it finishes installing)
- After the installation, reboot your computer

### Hiding the controller

- Open the "HidHide Configuration Client" in the start menu
![HidHideClient_StartMenu](images/HidHideClient_StartMenu.png)
- On the Configuration Client, click on the `Devices` tab to show the list of connected controllers
- Have the controllers you want to hide connected to your computer
- On your controllers entries, mark the white box before their names. A red lock icon should appear
- If your controller can connect both via cable and Bluetooth, reconnect your controllers via the other connection method and also mark their new entries
- Mark the box in the bottom called "Enable Device Hiding" to (obviously) activate the hiding of the marked devices

### Verifying if the controllers are hidden

At this point, your controllers should be hidden to everything. To verify, open Windows' `joy.cpl` by one of the following methods:

- Pressing the key combination ++win+r++ and then entering `joy.cpl` ___OR___
- Searching and opening on Windows' Start Menu `Set up USB Game Controllers` 

Assuming the hidden controllers are the only ones connected to the system and there are no virtual controllers being emulated, no device should show up in the Game Controller's list. If your real controller is still on the list, try reconnecting them. 

### Allowing chosen applications to see hidden devices

Now that it's confirmed your controllers are hidden, you need to select which applications should be able to detect them anyway:

- On the Configuration Client, click on the `Applications` tab
- Click on the `+` icon and add the executable file of your application (`ApplicationName.exe`)  to whitelist it
- Repeat the step above for each application that should whitelisted
- After that, fully close then reopen your application (in case it was running) for it to detect the hidden devices. Alternatively, just reconnect your controllers.

From this point, the applications on the list should be able to detect the hidden devices. The image below is an example of the application "UCR" being able to see a hidden Controller and emulating a DualShock 4: 
![HidHideExampleSetup](images/HidHideClient_ExampleSetup.png)

!!! important "Users of DS4Windows: PAY ATTENTION!"
    If you are running DS4Windows under a custom `.exe` name (look at your DS4Windows' `Other` tab) then the custom named executable must also be added to the list

## What now?

If you've set everything correctly then all that is left is for you to enjoy! Before you leave, have a quick look in the next section and on the `Frequently Asked Questions` article on the left side-bar (I mean... if it has already been created).

## Things to keep in mind

Common things to know regarding using HidHide with your controllers:

- Contrary to HidGuardian, HidHide affects isolated devices instead of device types. This means that if you have (for example) 4 different controllers that are the exact same model, you would still need to mark each one as hidden separately, both on USB and on Bluetooth
- HidHide whitelists applications based on their location in your computer. This means that if you whitelist "UCR.exe" that is on your desktop, but then move it to another folder you will need to whitelist it again on its new location
- If you think something is wrong and want to disable HidHide to run tests, just open the `HidHide Configuration Utility`, go into the `Devices` tab and un-check the `Enable Device Hiding` checkbox. If this doesn't make the devices visible again, try then reconnecting them
- Applications may add native support to HidHide in future updates, automating the process by whitelisting themselves and auto-hiding detected controllers



