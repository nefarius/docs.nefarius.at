# SCP XInput Bridge (Proxy DLL)

DsHidMini ships with a custom `XInput1_3.dll` you can drop in the game directory and use together with **SXS** mode to fake an Xbox 360-compatible pad for that particular game. Some games/mods/emulators even support the pressure sensitivity extension (like [GInput by Silent](https://cookieplmonster.github.io/mods/gta-sa/#ginput) and [PCSX2 Qt Edition](https://pcsx2.net/downloads/)). See the video tutorials below.

## Latest downloads

The DLLs included in the GitHub releases can be outdated, the latest builds from Continuous Integration (build server) can be downloaded here. Those contain the latest features and bug fixes but might still contain unaddressed issues. When in doubt, stick to the GitHub release copies.

The DLL architecture has to match your game/emulator or it will result in errors.

- [x64 (64-Bit Intel/AMD)](https://buildbot.nefarius.at/builds/DsHidMini/latest/bin/x64/XInput1_3.dll) (most used)
- [x86 (32-Bit Intel/AMD)](https://buildbot.nefarius.at/builds/DsHidMini/latest/bin/x86/XInput1_3.dll)
- [ARM64 (64-Bit ARM)](https://buildbot.nefarius.at/builds/DsHidMini/latest/bin/arm64/XInput1_3.dll)

## Usage in games

User feedback is required to expand this article 🙃 If you know of any tools or games we could link or explain here, contact us on Discord or open a GitHub issue!

### GTA San Andreas

<iframe id="odysee-iframe" width="560" height="315" title="DsHidMini SCP XInput Bridge - GTA San Andreas demo" src="https://odysee.com/$/embed/DsHidMini-SCP-XInput-Bridge-Installation-and-Demo-in-GTA-San-Andreas/968346b7254b57fa72722bd3d6c82b0d092ea2e9?r=EF18PBBCqrYYikMYYk7Gkq32SAU7j8H1" allowfullscreen></iframe>

### RPCS3 and PCSX2 Qt edition

<div class="video-wrapper">
  <iframe width="560" height="315" src="https://www.youtube.com/embed/gnC7cFKXpiw" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
</div>
