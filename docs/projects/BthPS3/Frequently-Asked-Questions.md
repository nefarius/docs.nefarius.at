# Frequently Asked Questions about BthPS3

Got questions? Who can blame you 😅 we can provide some answers, though! Read on, traveler!

## How to fix this setup message?

> Bluetooth Host Radio not found. A working Bluetooth stack is required for driver installation or removal.

![Error message](images/glvDeYjpQi.png)

Your Bluetooth isn't working 🙂 If you're on a Laptop, make sure you haven't disabled wireless either via a physical switch or a key combination (depends on the device model). On Desktop, make sure you actually have a Bluetooth dongle plugged in 😉 If you had other solutions like ScpToolkit or AirBender installed, make sure they have been removed completely and you run stock drivers. If you don't see the little Bluetooth tray icon in your taskbar, chances are your Bluetooth isn't working or turned on. Fix it and setup will be happy 😘

## How to fix "previous version found" on reinstall?

If you're getting this setup error...

![Error message](images/previous-version-found.png)  

...and can't get rid of it, do the following:

Let's assume you downloaded `BthPS3Setup_x64.msi` to `F:\Downloads` (adjust for your particular system's paths accordingly), open a `cmd`/`PowerShell`/`Terminal` as Administrator:

![Start menu](images/JfVi16IRZJ.png)  

In the resulting window insert the following lines (followed by an Enter key press):

- `cd "F:\Downloads\"`
    - Replace `F:\Downloads\` with wherever **you** downloaded the setup to! For example `C:\Users\<yourUsernameHere>\Downloads`
- `.\BthPS3Setup_x64.msi FILTERNOTFOUND="1"`

Now the setup should launch bypassing the error message. Follow the setup's instructions and you're done.

## How to fix Bluetooth device error codes 19 & 39?

... or Code 31 or Code 37 or Code 43. If you end up with a damaged/partial installation for whatever reason (computers, right? 😅) the setup or uninstaller might not even be able to do its work. Worry not though, if you check Device Manager and see that yellow exclamation mark on your Bluetooth host device, check the details and if they give you a familiar error code, like...

![Error Code 19](images/host-error-19.png)  

...or...

![Error Code 39](images/host-error-39.png)  

...or...

![Error Code 31](images/intel-driver-error-31.png)  

...or...

![Error Code 43](images/error-code-43.png)  

...this may look frightening, but in essence is an easy fix.

Fire up PowerShell as Administrator and execute:

!!! example "PowerShell"
    ```PowerShell
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{e0cbf06c-cd8b-4647-bb8a-263b43f0f974}' -Name 'LowerFilters'
    ```

This removes the requirement to load the filter driver, which might be missing, and therefore prohibiting your radio to boot properly. After this line got executed, either power-cycle your radio or simply reboot and see if that issue got fixed ❤️ You may also need to uninstall and install BthPS3 again to completely fix the issue.

## What do do about error Code 10 `STATUS_DEVICE_POWER_FAILURE`?

> This device can not start. (Code 10)

![Code_10](images/code_10.png)  

Your Bluetooth host dongle/card is too old or incompatible 🙂 Time to upgrade or switch to something slightly more expensive and sturdy 🤞 There is no software-fix possible for this error.

### What about Code 10 `The specified request is not a valid operation for the target device.`?

![Code_10](images/kppi8Fg8Qx.png)

Your Bluetooth host dongle/card is incompatible 🙂 Time to switch to something slightly more expensive and sturdy 🤞 There is no software-fix possible for this error.

## What Bluetooth hosts are supported?

In short: all of them manufactured within the last decade and running proper stock drivers (means no ScpServer/ScpToolkit, no AirBender, stock as the manufacturer intended). [For details see this article](Compatible-Bluetooth-Devices.md).

!!! warning "There's a catch"
    Only host radios using **USB** are supported! This includes the majority of external dongles or integrated cards (they use USB under the hood to connect to the rest of the system). So if your device is using something more exotic like I²C or UART, I'm afraid that's not gonna work 😔

## What controllers are supported?

!!! important "TL;DR"
    The genuine original Sony hardware, anything else is a nice-to-have that may or may not work ✨

This is unfortunately impossible to answer a 100% correctly. These drivers have been designed with compromises in mind. They aim to support the **original genuine Sony SIXAXIS/DualShock 3** (and Navigation, Move) controllers while operating within the realms of possibilities the Microsoft Bluetooth stack offers and allows. The DualShock 3 (or DS3 in short) has been a fairly popular piece of hardware and many clones have arisen over time, some coming close to the quality of the original, some... well, not quite as much. Aftermarket devices spoof (forge) the Hardware Identification Information that Windows sees and the labels and manufacturer notes on the housing itself. There simply is no rock-solid way to properly identify these devices to separate the good from the ugly. That's the inconvenient truth, any other statement would be a wild guess and not facts. [For details see this article](About-Controller-Compatibility.md).

## Can I use my wireless Keyboard/Mouse/Headphones with this?

Yes, that's the whole purpose of this design 😉 BthPS3 *extends* the existing vanilla Bluetooth stack, it doesn't *replace* it (like ScpToolkit and alike did). This means it can never be as close to the original PlayStation Bluetooth stack (we need to play by Microsoft's design rules, remember?) as other solutions but the trade-off of keeping your stock wireless functionality should be worth it.

## How many devices can I connect at the same time?

There is no definitive answer to that one, as it depends heavily on the Bluetooth host hardware (quality, antenna design, size and position) and the amount of "noise" in your environment (Bluetooth is a fairly "weak" protocol compared to all the other radio chatter that's constantly happening in a common household). Users have reported all sorts of working constellations; like up to 6 controllers connected and working concurrently without any human-noticeable delay. So it's up to you to figure this one out! 😁

## Can it emulate another common controller, like Xbox One?

Controller emulation is *not* the job of these drivers, they provide the plumbing required to get them connected to Windows (and stay connected and keep talk), nothing more, nothing less. Other drivers (which you can find on this site) handle the controller-specific work required.

## Is there any noticeable input lag over Bluetooth?

Another stellar question! With no definite answer 😅 The truthful answer would be: don't know, don't care since it hasn't been measured with scientific equipment. The more down-to-earth answer comes from simple experience and interaction, human to machine: no. You might feel it working better or worse compared to USB, real or placebo. Those who ask this question usually just wanna hear "nope, it's all fine" so that they can move on. Well, there you have it, you can move on now 😘

## Why is the DualShock 4 even supported?

Because I can 😜 literally. It wasn't much extra work to add DS4 compatibility, as under the hood it operates quite similar to the DS3, without the unnecessary quirks. The DualShock 4 works natively without any custom drivers on Windows if paired in "PC mode" (PS and share button pressed at the same time until the light bar flashes rapidly), but a little known "secret" about this device is, that by default it operates in "PS mode" (PlayStation Bluetooth compatible) which BthPS3 can emulate! For now this doesn't really have any real-world advantages but leaves a backdoor for experimentation, if adventurous developers wanna talk to it they way the PlayStation originally does.

## How do I uninstall this?

In case you don't want/need the software anymore or you're getting this setup message:

![msiexec_2e33lI1uwF.png](../../images/msiexec_2e33lI1uwF.png)

Simply head over to Apps & features and uninstall from there:

![qBS61SD83D.png](../../images/qBS61SD83D.png)

Follow the instructions of the uninstaller and you're all set! 👋

## Why does it not work on the Raspberry Pi 4?

If you're running [Windows on Raspberry](https://worproject.com/) and attempt to install BthPS3 you will be greeted by error `Code 31` in Device Manager:

![vEOfeRh9vF.png](images/vEOfeRh9vF.png)

Note the `UART` in the parent device. Unfortunately the mandatory filter driver that ships with BthPS3 work with **USB only**, not UART. Therefore this solution is unable to operate on the Raspberry Pi 4 and any other device that uses UART for Bluetooth.

## Can I install this on the Steam Deck?

No, BthPS3 will not work on the Steam Deck [since it uses UART, not USB](#why-does-it-not-work-on-the-raspberry-pi-4).

![hZszQF3qc1.png](images/hZszQF3qc1.png)

![tey5NNAkBg.png](images/tey5NNAkBg.png)

## Why does the driver stop working after turning Bluetooth off and on again, or on hibernate/sleep?

If you are using **Intel(R) Wireless Bluetooth(R)** (quite common in Laptops) you can run into the following issue:

```text
This device can not start. (Code 10)

STATUS_DEVICE_POWER_FAILURE
```

![intel-wireless-status-device-power-failure.png](images/intel-wireless-status-device-power-failure.png)

Actions triggering this can be either waking up from sleep/hibernate or by manually turning Bluetooth off and on via the Windows-provided buttons:

![windows-bluetooth-switch.png](images/windows-bluetooth-switch.png)

Afterwards the profile driver greets you with a yellow exclamation mark:

![intel-wireless-power-fail.png](images/intel-wireless-power-fail.png)

**This is a problem caused by Intel Wireless and can not be fixed.** To mitigate, either do not disable and enable Bluetooth during operation, or use a different Bluetooth host.
