# Command Line Arguments

The default behaviour of the updater if invoked without any CLI arguments is to display the main window if updates are found or message dialogs in case of errors. The following CLI switches are supposed to be used for setting up the updater on the consumer system and customizing it further.

## Common

### `--install`

Typically called with only once when the bundled product gets installed. Performs self-registration in current users' autostart and daily runs via Task Scheduler. Errors will be logged but the user will not be actively notified. Check the exit code for potential error cases.

!!! important "Beware of the target directory permissions"
    If your updater instance gets deployed into a restricted directory (like `Program Files`) this command needs to be invoked with administrative privileges or some steps requiring write-permissions will fail.

!!! warning "Prerequisite for self-updating feature"
    The install routine must be run at least **once** or the self-update feature will not be available.

!!! warning "Beware of parent path changes"
    If the updater executable is moved to a different location, this command needs to be issued again at least once.

### `--uninstall`

Removes the autostart registration and deletes the scheduled task job.

### `--skip-self-update`

Skips the self-update procedure, even if a newer version is available.

### `--silent`

Suppresses any UI interaction, even when updates are found.

Check the app [exit code](Exit-Codes.md) for status details.

### `--ignore-busy-state`

Ignores if the user session is busy and displays the main window if updates were found.

### `--log-level <value>`

Alters the default logging level (`info`) to the provided `<value>`.

Possible values are: `trace`, `debug`, `info`, `warn`, `err`, `critical` or `off`.

### `--log-to-file <value>`

Logs to the file specified in `<value>` in addition to the default debug sink.

!!! warning "Ensure the target path is writable"
    Bear in mind that the log file path needs to be writable for the user executing the updater. It will fail silently if it couldn't write to the specified file.

## Internal

!!! warning "Beware of altering"
    The following arguments are set or removed by other [common](#common) commands and should not be altered by the user.

### `--autostart`

Performs tasks on user logon like checking self-integrity and searching for updates.

### `--background`

Tells the updater it's run by Task Scheduler. It will not display any UI except when an update has been found. Errors will be logged but the user will not be actively notified.

## Self-Updater

The following parameters are passed from the main updater process to the self-updater module.

They can not be altered by the user.

### `--pid`

The Process ID of the parent updater process that invoked the self-update module.

### `--url`

The direct download URL of the latest updater executable.

### `--path`

The absolute path to the local updater executable.
