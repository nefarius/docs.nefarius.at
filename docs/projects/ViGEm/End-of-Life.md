# End of Life Statement

TBD

## Adjust Automatic Updater COnfiguration

### Configure ViGEm Bus Driver

Navigate to the path `C:\Program Files\Nefarius Software Solutions\ViGEm Bus Driver` and edit the file `ViGEmBus_Updater.ini` with a text editor of your choice (you will need Administrator permissions to edit). Find the following line:

```ini
URL=https://updates.vigem.org/api/github/ViGEm/ViGEmBus/updates
```

Change it to:

```ini
URL=https://aiu.api.nefarius.systems/api/github/ViGEm/ViGEmBus/updates
```

Save it an you're done!

### Configure HidHide

Navigate to the path `C:\Program Files\Nefarius Software Solutions\HidHide` and edit the file `HidHide_Updater.ini` with a text editor of your choice (you will need Administrator permissions to edit). Find the following line:

```ini
URL=https://updates.vigem.org/api/github/ViGEm/HidHide/updates
```

Change it to:

```ini
URL=https://aiu.api.nefarius.systems/api/github/ViGEm/HidHide/updates
```

Save it an you're done!

## Uninstall Applications

If you're not using any software relying on either ViGEmBus or HidHide you can simply uninstall them via `Apps & Features`.

### Uninstall ViGEm Bus Driver

![Apps and Features - ViGEm Bus Driver](images/ApplicationFrameHost_WaHYm3RoSi.png){: .glightbox }  

### Uninstall HidHide

![Apps and Features - HidHide](images/ApplicationFrameHost_7f83G2M1hS.png){: .glightbox }  
