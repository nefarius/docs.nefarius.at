# Manual installation on ARM64

Manual ARM64 builds of HidHide are provided for advanced users who need to deploy the driver on devices where the standard x64 MSI installer does not work (e.g., Windows on ARM laptops or single-board PCs). This guide walks you through installing the driver and configuration client without the MSI.

!!! warning
    These steps are intended for Windows on ARM64 systems. Installing the ARM64 package on x86 or x64 editions of Windows will fail.

## Prerequisites

- Administrator account on Windows 10/11 ARM64.
- Latest [Microsoft Visual C++ Redistributable](https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist?view=msvc-170) for ARM64 (required for the configuration client).
- Ability to extract a `.zip` archive.

## Download the ARM64 package

1. Download the ARM64 manual installation archive directly: [HidHide_ARM64.zip](https://github.com/nefarius/HidHide/raw/refs/heads/master/drivers/HidHide_ARM64.zip).
2. Unblock the archive if Windows marks it as downloaded from the internet (Right-click → **Properties** → **Unblock** → **OK**).
3. Extract the archive to a folder you can access easily (e.g., `C:\Temp\HidHide_ARM64`). Extraction creates a folder `HidHide_ARM64` containing `HidHide.inf`, `HidHide.sys`, `HidHide.cat`, and `LICENSE.rtf`.

## Install the driver with `pnputil`

1. Open **Windows Terminal** or **PowerShell** as **Administrator**.
2. Change into the extracted driver folder (e.g., `C:\Temp\HidHide_ARM64\HidHide_ARM64`). The folder must contain `HidHide.inf` alongside `HidHide.sys` and `HidHide.cat`.
3. Run the following command to add and install the driver:

    ```powershell
    pnputil /add-driver HidHide.inf /install
    ```

4. Wait for the command to report **Driver package added successfully** and **Driver package installed on device(s)**. If you see signature warnings, verify that Secure Boot is enabled and that you downloaded the official release archive.
5. Reboot Windows to make sure the filter driver is active for HID and XInput devices.

## Install the configuration client

The archive also includes an ARM64 build of the configuration client. Copy the client files (usually inside a `Client` or `bin` subfolder) to a location of your choice, then create a Start menu shortcut if desired. Launch `HidHideClient.exe` to manage hidden devices and application whitelists.

!!! tip
    If the client fails to start, install the ARM64 VC++ Redistributable and try again.

## Updating to a newer version

1. Download and extract the latest ARM64 manual archive as above.
2. Re-run the `pnputil /add-driver HidHide.inf /install` command from the new folder. This will stage and apply the updated driver.
3. Replace the configuration client files with the versions from the new archive.
4. Reboot Windows.

## Uninstalling the manual installation

1. Open an elevated **PowerShell** window in the folder that contains `HidHide.inf`.
2. Remove the driver package and its devices:

    ```powershell
    pnputil /delete-driver HidHide.inf /uninstall /force
    ```

3. Delete the configuration client files you copied earlier.
4. Reboot Windows to remove the filter from device stacks.

!!! important
    Do not mix the manual ARM64 installation with the standard x64 MSI setup on the same system. Stick to one installation method to avoid driver duplication.
