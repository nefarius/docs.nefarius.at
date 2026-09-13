# Frequently Asked Questions

## I have a different question, how can I reach you folks?

[Head over to the support page](../../Community-Support.md), we prefer Discord.

## Can it hide mice, keyboards, touch- or trackpads? {#hide-mice-keyboards}

Unfortunately not. Mouse and Keyboard inputs travel through different means and routes through Windows and HidHide's blocking mechanism can not interfere with those in the same fashion as it does with Joysticks and Gamepads.

The same limit applies to **Raw Input**. Some applications (voice macros, overlay tools, and similar) read devices through that path and will still see a cloaked controller. HidHide cannot block Raw Input.

Cloaking is also **all or nothing per device**. You cannot hide a single button (Share, mute, volume, and so on) while leaving the rest of the pad visible. If those keys are not a separate HID device you can leave uncloaked, HidHide cannot split them out.

A major redesign would be required to make this a reality, bear in mind that HidHide is a hobby project so the authors can not make any promises as many other tasks in life have priority. If any developer would be interested in this topic, contact us! 😄

## Where can I download a Windows 7/8 setup?

Thanks to [driver signing](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/driver-signing) restrictions we lack the means and motivation to support anything below Windows 10/11 so these are the only OS editions we support.

## Where can I download a 32-Bit or ARM64 (Mac, RasPi) version?

At this point we only provide a setup for **Intel/AMD 64-Bit** installations. Follow [this issue](https://github.com/nefarius/HidHide/issues/57) for potential news about this topic.

## How to fix 'This package can only be run from a bootstrapper' message?

![AnyDesk_STmajKjQwQ.png](images/AnyDesk_STmajKjQwQ.png)

Simply download and run the latest setup, go through the installation again and you're done.

## I hid my device, but the application can still see it

Check these in order; more than one can be true at the same time.

**Inverse application cloak.** On the Applications tab, inverse cloak hides the marked devices *only* from the programs on that list and leaves them visible to everything else. If games still see the pad, turn inverse cloak **off**. The normal mode is the opposite: hidden from every process except the ones you whitelist.

**Xbox / XInput devices.** Cloaking Xbox 360, Xbox One, and similar XInput controllers through the configuration client is a [known limitation](https://github.com/nefarius/HidHide/issues/39) and is not reliable. If an Xbox pad stays visible after a stack rebuild, that is this issue, not a missed checkbox.

**Raw Input.** Some applications never use the HID/XInput path HidHide can intercept. Those apps will keep seeing the device; see [Can it hide mice, keyboards, touch- or trackpads?](#hide-mice-keyboards).

**Stale device stack after install.** HidHide's filter driver only attaches to device stacks that are created **after** the driver was registered. If you configured cloaking immediately after installing HidHide, devices that were already enumerated are still running on a stack with no filter attached, so they remain visible even though the configuration looks correct.

Confirm with `HidHideCLI.exe --cloak-state` and `--dev-list`; if the device is listed as hidden but an unauthorized application still sees it, the stack needs rebuilding.

The fix is to force the device stack to be rebuilt. In order of convenience:

**Option 1 — replug the device (simplest).** Unplug the device and plug it back in. This tears down and recreates the whole stack, and cloaking takes effect immediately.

**Option 2 — disable and re-enable the device in Device Manager.** Does the same job without touching the cabling, so it's the practical choice for devices you can't easily unplug. See the walkthrough below.

**Option 3 — reboot.** Achieves the same thing, but it's the slowest route and is rarely necessary — reach for it only if neither of the above is possible.

#### Rebuilding the stack from Device Manager

Note that for a USB HID device, *both* the parent and child nodes appear under **Human Interface Devices** — the parent is not under "Universal Serial Bus controllers", despite having a `USB\...` instance path. The two nodes are typically:

- parent: `USB\VID_xxxx&PID_xxxx\...`, usually displayed as **USB Input Device**
- child: `HID\VID_xxxx&PID_xxxx\...`, e.g. **HID-compliant game controller**

Disabling and re-enabling the **parent** node rebuilds the child along with it.

Be aware that every USB HID device on the system produces an entry named "USB Input Device", so there may be many identical-looking entries. To identify the right one, open its **Properties → Details** tab and check **Bus reported device description**, which shows the real product name (e.g. `TWCS Throttle`). **Device instance path** on the same tab confirms the VID/PID.

Equivalent from an elevated PowerShell prompt, if you already know the instance path:

```powershell
$id = 'USB\VID_044F&PID_B687\7&33565146&0&1'   # your device's parent node
Disable-PnpDevice -InstanceId $id -Confirm:$false
Start-Sleep -Seconds 3
Enable-PnpDevice  -InstanceId $id -Confirm:$false
```

To list candidate parent nodes with their real product names:

```powershell
Get-PnpDevice -Class HIDClass -PresentOnly |
  Where-Object InstanceId -like 'USB\*' |
  ForEach-Object {
    [pscustomobject]@{
      Product    = (Get-PnpDeviceProperty -InstanceId $_.InstanceId |
                    Where-Object KeyName -eq 'DEVPKEY_Device_BusReportedDeviceDesc').Data
      InstanceId = $_.InstanceId
    }
  } | Format-Table -AutoSize
```

## Why did an application appear on the Applications list by itself?

HidHide only adds its own configuration client. Third-party software that integrates with HidHide can whitelist itself through the [public API](API-Documentation.md). If an entry keeps coming back after you remove it, that program is adding it — ask that vendor to stop, or leave the entry and use inverse cloak only if you understand the inversion above.

## HidHide does not seem to hide anything at all

Nine times out of ten **inverse application cloak** is on, or hiding is off on the Devices tab. Confirm that:

- **Enable device hiding** is checked
- Inverse application cloak is **unchecked** unless you really want the inverted logic
- The controller row shows the red lock on **both** USB and Bluetooth if it uses both
- You [rebuilt the device stack](#i-hid-my-device-but-the-application-can-still-see-it) after changing the list
