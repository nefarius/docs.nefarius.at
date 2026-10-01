# About BthPS3

[![GitHub](https://img.shields.io/badge/GitHub-yellowgreen?logo=github)](https://github.com/nefarius/BthPS3) ![Maintained](https://img.shields.io/badge/Project%20actively%20maintained-brightgreen)

Welcome to the BthPS3 extended documentation.

Here you can find documentation on the different parts of this project, the devices it supports, and answers to common issues and questions.

!!! info "What's new in BthPS3 v3"
    **BthPS3 v3.0.0** adds support for Bluetooth host radios on Microsoft's Bluetooth Extensibility Transport (BTHX) bound to `BthMini.sys`—for example Intel PCIe `iBtPciBus`—in addition to USB. See [What Bluetooth hosts are supported?](Frequently-Asked-Questions.md#what-bluetooth-hosts-are-supported) and [How to Install](How-to-Install.md). **BthPS3 v2.x** remains USB-only.

    **v3.1** and **v3.2** add structured ETW events for PSM registration, remote connect, filter initialization, and BTHX transport so connection problems are easier to diagnose. See [Debugging the drivers](Debugging-the-drivers.md#interpreting-common-events).

    Current setup also installs a [built-in updater](Frequently-Asked-Questions.md#does-bthps3-update-itself). GitHub Releases may use `setup-v3.x.y` or `setup-v3.x.y-rN` tags while the MSI product version stays `MAJOR.MINOR.PATCH`. Download the latest published MSI from [GitHub Releases](https://github.com/nefarius/BthPS3/releases).

- **Compatible Bluetooth hardware:** Check whether your Bluetooth host radio has been confirmed working or help document a new one—see the [compatible devices list](Compatible-Bluetooth-Devices.md).
- **Controllers not connecting:** If your PS3 controllers refuse to connect, see [controller compatibility](About-Controller-Compatibility.md).
- **DualShock 4 issues:** Having trouble getting the DualShock **4** to work with BthPS3 installed? See the [DualShock 4 FAQ](DualShock-4-FAQ.md).
- **Driver debugging:** To explore the inner workings of the drivers, see [enabling the trace log](Debugging-the-drivers.md).
- **Updates:** The v3 MSI registers `nefarius_BthPS3_Updater.exe`. See [Does BthPS3 update itself?](Frequently-Asked-Questions.md#does-bthps3-update-itself).
