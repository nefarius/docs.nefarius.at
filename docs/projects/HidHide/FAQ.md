# Frequently Asked Questions

## I have a different question, how can I reach you folks?

[Head over to the support page](../../Community-Support.md), we prefer Discord.

## Can it hide mice, keyboards, touch- or trackpads?

Unfortunately not. Mouse and Keyboard inputs travel through different means and routes through Windows and HidHide's blocking mechanism can not interfere with those in the same fashion as it does with Joysticks and Gamepads.

A major redesign would be required to make this a reality, bear in mind that HidHide is a hobby project so the authors can not make any promises as many other tasks in life have priority. If any developer would be interested in this topic, contact us! 😄

## Where can I download a Windows 7/8 setup?

Thanks to [driver signing](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/driver-signing) restrictions we lack the means and motivation to support anything below Windows 10/11 so these are the only OS editions we support.

## Where can I download a 32-Bit or ARM64 (Mac, RasPi) version?

At this point we only provide a setup for **Intel/AMD 64-Bit** installations. Follow [this issue](https://github.com/nefarius/HidHide/issues/57) for potential news about this topic.

## How to fix 'This package can only be run from a bootstrapper' message?

![AnyDesk_STmajKjQwQ.png](images/AnyDesk_STmajKjQwQ.png)

Simply download and run the latest setup, go through the installation again and you're done.

## I hid my device, but the application can still see it

HidHide's filter driver only attaches to device stacks that are created **after** the driver was registered. If you configured cloaking immediately after installing HidHide, devices that were already enumerated are still running on a stack with no filter attached, so they remain visible even though the configuration looks correct.

Confirm with `HidHideCLI.exe --cloak-state` and `--dev-list`; if the device is listed as hidden but an unauthorized application still sees it, the stack needs rebuilding.

To fix without rebooting, force the device stack to rebuild:

1. Open Device Manager and enable **View → Devices by connection**, or locate the device's parent **USB container** entry (for example `USB\VID_044F&PID_B687\...`, as opposed to the child `HID\...` node).
2. Disable the USB container entry, wait a few seconds, then re-enable it.

Cloaking takes effect immediately afterwards. Rebooting achieves the same thing.
