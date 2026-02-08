# Major Version 3

![controlapp-preview-image.jpg](images/controlapp-preview-image.jpg)

## Before proceeding...

- DsHidMini V3 is under active development. This means there may be unresolved issues or features that are not yet implemented.
    - This does *not* mean that horrible things like you PC catching fire can occur. If it does tho, I recommend having a fire extinguisher at hand.
- You can always go back to v2 if the experience is not (yet) to your liking, this is not a one-way-street.
- Before asking questions about what new features are available or which bugs were fixed **check both the [open](https://github.com/nefarius/DsHidMini/milestone/7) and [closed](https://github.com/nefarius/DsHidMini/milestone/7?closed=1) issues and PRs on GitHub** first! We know reading can be tedious, but repeatedly answering the same questions is equally frustrating for us.

## Highlights

The following features are considered done and have been tested to the best of the abilities to a two-head development team 😉

- Native **Xbox One Controller emulation**
    - Test as many modern games in this mode as you like, [feedback welcome](https://github.com/nefarius/DsHidMini/discussions/114)!
- Full Windows 11 compatibility
    - From now on the driver will be signed by Microsoft
- A new configuration tool, which allows you to...:
    - configure LED behavior
    - change/disable the combo used to turn off the controller when wireless
    - adjust the deadzone of the sticks
    - tweak rumble settings
    - etc
- ARM64 builds of the driver
    - ~~Currently **untested**, feedback welcome!~~
    - Appears to work fine on Apple Silicon using Windows 11 on Parallels
- To be filled...

## Installation, removal and troubleshooting

- [V3 installation and removal](How-to-Install.md)
- [HID Device Modes explained](HID-Device-Modes-Explained.md) — SXS, XInput, DS4Windows, SDF, GPJ
- [XInput mode (default) — setup and Steam](XInput-Mode-Explained.md)
- [DS4Windows mode user guide](DS4-Mode-User-Guide.md)
- [Output rate control (Bluetooth)](Output-Rate-Control-Explained.md)
- [SCP XInput Bridge (proxy DLL for games)](SCP-XInput-Bridge.md)
- [Switch from SIXAXIS.SYS to DsHidMini](SIXAXIS.SYS-to-DsHidMini-Guide.md)
- [Frequently Asked Questions](FAQ.md)
