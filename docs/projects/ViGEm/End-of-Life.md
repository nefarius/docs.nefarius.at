# End of Life Statement

TBD

## Adjust Automatic Updater Configuration

### Configure ViGEm Bus Driver Updater

!!! warning "This is the recommended action if you're running Windows 10/11"
    If you're running ViGEm Bus Driver **v1.21.442 or older** the following section applies to you and is highly recommended to follow until software updates become available (if ever).

Navigate to the path `C:\Program Files\Nefarius Software Solutions\ViGEm Bus Driver` and edit the file `ViGEmBus_Updater.ini` with a text editor of your choice (you will need Administrator permissions to edit). Find the following line:

```ini
URL=https://updates.vigem.org/api/github/ViGEm/ViGEmBus/updates
```

Change it to:

```ini
URL=https://aiu.api.nefarius.systems/api/github/ViGEm/ViGEmBus/updates
```

Save it an you're done! From now on the updater agent will contact the new server to check for software updates.

#### For Windows 7/8/8.1 Users

!!! warning "This is the recommended action if you're running Windows 7/8/8.1"
    If you're running ViGEm Bus Driver **v1.16.116 or older** the following section applies to you and is highly recommended to follow as there won't be any new updates made available.

Find and open "Task Scheduler", select `Task Scheduler Library` on the left-hand side, select the `ViGEmBusUpdater` entry in the center panel, right-click it and select `Delete`:

![a2Vw8mojOW.png](images/a2Vw8mojOW.png)

Confirm and you're done!

![vmware_8YQZ16Tjyi.png](images/vmware_8YQZ16Tjyi.png)

From now on your PC will no longer check for updates and no update pop-ups will nag you ever again!

### Configure HidHide Updater

!!! warning "This is the recommended action if you're running Windows 10/11"
    If you're running HidHide **v1.2.128 or older** the following section applies to you and is highly recommended to follow until software updates become available (if ever).

Navigate to the path `C:\Program Files\Nefarius Software Solutions\HidHide` and edit the file `HidHide_Updater.ini` with a text editor of your choice (you will need Administrator permissions to edit). Find the following line:

```ini
URL=https://updates.vigem.org/api/github/ViGEm/HidHide/updates
```

Change it to:

```ini
URL=https://aiu.api.nefarius.systems/api/github/ViGEm/HidHide/updates
```

Save it an you're done! From now on the updater agent will contact the new server to check for software updates.

## Uninstall Applications

If you're not using any software relying on either ViGEmBus or HidHide you can simply uninstall them via "Apps & Features". Same can be achieved by the old "Programs and Features" section in the Control Panel.

### Uninstall ViGEm Bus Driver

Search for `ViGEm` and uninstall:

![Apps and Features - ViGEm Bus Driver](images/ApplicationFrameHost_WaHYm3RoSi.png)

### Uninstall HidHide

Search for `HidHide` and uninstall:

![Apps and Features - HidHide](images/ApplicationFrameHost_7f83G2M1hS.png)
