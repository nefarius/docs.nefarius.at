# About HidHide

[![GitHub](https://img.shields.io/badge/GitHub-yellowgreen?logo=github)](https://github.com/nefarius/HidHide) ![Maintained](https://img.shields.io/badge/Project%20actively%20maintained-brightgreen)

HidHide is an "input device firewall" inspired by HidGuardian but designed and written from scratch. It allows for blocking individual applications access to HID and XInput devices, allowing users to re-route and re-map controller inputs as they please.

!!! danger highlight "Kaspersky Anti-Virus can interfere with whitelisting feature"
    If you run **Kaspersky Anti-Virus** chances are you encounter issues with program whitelisting due to Kaspersky transparently breaking the process detection logic of HidHide. This is an issue with Kaspersky, please consult their support or disable it while you want to use HidHide to its full potential ❤️

## Downloads

[Get the setup here](https://github.com/nefarius/HidHide/releases/latest) and follow its instructions. Done!

## ARM64 manual installation

Need to deploy HidHide on Windows on ARM? Follow the [manual ARM64 installation guide](Manual-Installation-ARM64.md) for a ZIP-based driver and client setup using `pnputil`.
