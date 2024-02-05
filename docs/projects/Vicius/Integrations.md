# Integrations

## Advanced Installer

Add the updater executable to your setup file structure:

![btnQ3mMSYE.png](images/btnQ3mMSYE.png)

Add a `Launch installed file` Custom Action to the installation pipeline, provide the command line `--install --override-success-code 0` and deselect `Uninstall` and `Maintenance` conditions:

![yfnLSVoyZm.png](images/yfnLSVoyZm.png)

Add a `Launch installed file` Custom Action to the removal pipeline, provide the command line `--uninstall --override-success-code 0` and deselect `Install` and `Maintenance` conditions:

![zzJBqQFsrK.png](images/zzJBqQFsrK.png)
