# Command Line Arguments

## `--install`

Typically called with only once when the bundled product gets installed. Performs self-registration in current users' autostart and daily runs via Task Scheduler. Errors will be logged but the user will not be actively notified. Check the exit code for potential error cases.

!!! important "Beware of the target directory permissions"
    If your updater instance gets deployed into a restricted directory (like `Program Files`) this command needs to be invoked with administrative privileges or some steps requiring write-permissions will fail.

!!! warning "Prerequisite for self-updating feature"
    The install routine must be run at least **once** or the self-update feature will not be available.

## `--uninstall`

Removes the autostart registration and deletes the scheduled task job.

## `--autostart`

Performs tasks on user logon like checking self-integrity and searching for updates.

## `--background`

Tells the updater it's run by Task Scheduler. It will not display any UI except when an update has been found. Errors will be logged but the user will not be actively notified.

## `--log-level <value>`

Alters the default logging level (`info`) to the provided `<value>`.

Possible values are: `trace`, `debug`, `info`, `warn`, `err`, `critical` or `off`.
