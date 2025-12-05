# Manual installation on ARM64

Manual ARM64 builds of HidHide are provided for advanced users who need to deploy the driver on devices where the standard x64 MSI installer does not work (e.g., Windows on ARM laptops or single-board PCs). This guide walks you through installing the driver and configuration client without the MSI.

!!! warning
    These steps are intended for Windows on ARM64 systems. Installing the ARM64 package on x86 or x64 editions of Windows will fail.

## Prerequisites

- Administrator account on Windows 10/11 ARM64.
- Latest [Microsoft Visual C++ Redistributable](https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist?view=msvc-170) for ARM64 (required for the configuration client).
- Ability to extract a `.zip` archive.

## Download the ARM64 package

1. Download the ARM64 manual installation archive directly: [HidHide_ARM64.zip](https://github.com/nefarius/HidHide/raw/refs/heads/master/drivers/HidHide_ARM64.zip). This archive contains only the driver and its catalog/INF files.
2. Unblock the archive if Windows marks it as downloaded from the internet (Right-click → **Properties** → **Unblock** → **OK**).
3. Extract the archive to a folder you can access easily (e.g., `C:\Temp\HidHide_ARM64`). Extraction creates a folder `HidHide_ARM64` containing `HidHide.inf`, `HidHide.sys`, `HidHide.cat`, and `LICENSE.rtf`.

## Install the driver with `nefcon`

`nefcon` is the preferred way to stage and install drivers from an `.inf` file. It is not bundled with Windows, so you need to download it first:

1. Download the latest Windows release ZIP from the [nefcon repository](https://github.com/nefarius/nefcon/releases/latest).
2. Extract the ZIP and copy `nefconc.exe` to a folder in your user profile (for example, `C:\Tools\nefcon`).
3. (Optional) Add that folder to your `PATH` so you can run `nefconc` from any directory:

    ```powershell
    setx PATH "$Env:PATH;C:\Tools\nefcon\x64"
    ```

4. Open **Windows Terminal** or **PowerShell** as **Administrator**.
5. Change into the extracted driver folder (e.g., `C:\Temp\HidHide_ARM64\HidHide_ARM64`). The folder must contain `HidHide.inf` alongside `HidHide.sys` and `HidHide.cat`.
6. Run the following command to add and install the driver via `nefcon` (if you did not add it to `PATH`, use the full path to `nefcon.exe`):

    ```powershell
    nefconc install HidHide.inf root\HidHide
    ```

7. Wait for **Driver package added successfully** and **Driver package installed on device(s)** in the output. If you see signature warnings, verify that Secure Boot is enabled and that you downloaded the official release archive.
8. Reboot Windows to make sure the filter driver is active for HID and XInput devices.

## Install the configuration client

The driver archive does **not** include the graphical or CLI configuration clients. Download the pre-built ARM64 client binaries from the latest build pipeline:

- [HidHide ARM64 client (GUI/CLI) binaries](https://buildbot.nefarius.at/builds/HidHide/latest/bin/Release/ARM64/)

After downloading, extract the archive and copy the client files to a location of your choice (e.g., `C:\Program Files\HidHide`). Then create a Start menu shortcut if desired. Launch `HidHideClient.exe` to manage hidden devices and application whitelists.

!!! tip
    If the client fails to start, install the ARM64 VC++ Redistributable and try again.

## Updating to a newer version

1. Download and extract the latest ARM64 manual archive as above.
2. Re-run the `nefcon driver install HidHide.inf` command from the new folder. This will stage and apply the updated driver.
3. Replace the configuration client files with the versions from the new archive.
4. Reboot Windows.

## Uninstalling the manual installation

1. Open an elevated **PowerShell** window in the folder that contains `HidHide.inf`.
2. Remove the driver package and its devices:

    ```powershell
    nefcon driver uninstall HidHide.inf --force
    ```

3. Delete the configuration client files you copied earlier.
4. Reboot Windows to remove the filter from device stacks.

!!! important
    Do not mix the manual ARM64 installation with the standard x64 MSI setup on the same system. Stick to one installation method to avoid driver duplication.
