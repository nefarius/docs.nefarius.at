# Command Line Arguments

The default behaviour of the updater if invoked without any CLI arguments is to display the main window if updates are found or message dialogs in case of errors. The following CLI switches are supposed to be used for setting up the updater on the consumer system and customizing it.

## Common

### `--install`

Typically called with only once when the bundled product gets installed. Performs self-registration in current users' autostart and daily runs via Task Scheduler. Errors will be logged but the user will not be actively notified. Check the exit code for potential error cases.

!!! important "Beware of the target directory permissions"
    If your updater instance gets deployed into a restricted directory (like `Program Files`) this command needs to be invoked with administrative privileges or some steps requiring write-permissions will fail.

!!! warning "Prerequisite for self-updating feature"
    The install routine must be run at least **once** or the self-update feature will not be available.

!!! warning "Beware of parent path changes"
    If the updater executable is moved to a different location, this command needs to be issued again at least once.

### `--no-scheduled-task`

Can be used in conjunction with the [`--install`](#-install) switch to skip the creation of the Scheduled Task. Useful if you rather wish to invoke the updater via your own mechanism, like a button in your product or whatever event works best for you.

### `--no-autostart`

Can be used in conjunction with the [`--install`](#-install) switch to skip registering in the current users autostart. Useful if you rather wish to invoke the updater via your own mechanism, like a button in your product or whatever event works best for you.

### `--uninstall`

Removes the autostart registration and deletes the scheduled task job.

### `--skip-self-update`

Skips the self-update procedure, even if a newer version is available.

### `--silent`

Suppresses any UI interaction, even when updates are found.

Check the app [exit code](Exit-Codes.md) for status details.

### `--silent-update`

Suppresses any UI, downloads and invokes the latest release found and exits afterwards.

Does nothing if the product is already up to date.

!!! important "Check exit codes for success or errors"
    This flag is most useful if you decide to trigger updates directly from your own application.  
    Make sure to check the [exit code](Exit-Codes.md) to react to possible errors during the update procedure.

### `--ignore-busy-state`

Ignores if the user session is busy and displays the main window if updates were found.

### `--log-level <value>`

Alters the default logging level (`info`) to the provided `<value>`.

Possible values are: `trace`, `debug`, `info`, `warn`, `err`, `critical` or `off`.

### `--log-to-file <value>`

Logs to the file specified in `<value>` in addition to the default debug sink.

!!! warning "Ensure the target path is writable"
    Bear in mind that the log file path needs to be writable for the user executing the updater. It will fail silently if it couldn't write to the specified file. See [Logging](Logging.md) article for more details.

### `--server-url`

!!! warning "Only available in DEBUG builds"
    This switch is intended to only work with DEBUG builds as it opens up a huge security problem if distributed to production systems. Any malicious process could attempt to direct the updater to a malignant server trying to then download and execute a payload that might further infect the target machine.

Overrides all other [Server Discovery](Server-Discovery.md) methods. Useful to quickly switch to different update configurations while testing the local debug build. The value is ignored in RELEASE builds, if set.

### `--channel <value>`

Specifies an alternate update channel to use. This value will be inserted into the server URL template e.g. `manufacturer/product/channel` which allows the caller to switch between [remote updater configurations](Remote-Configuration.md) when invoking the updater manually. This can be used to deliver different update mechanisms for Beta or VIP users etc.

The value can be any alphanumeric string **excluding** the following characters:

- `'..'` (two consecutive dots)
- `'/'` (forward slash)
- `'\'` (backslash)
- `' '`&nbsp;(space)

### `--add-header <name=value>`

Allows for adding one or more additional HTTP headers to be added to the update server request. This can be used in conjunction with a backend application server to influence delivery of the [remote configuration](Remote-Configuration.md) based on certain custom client parameters.

This parameter can be specified multiple times with different name-value-pairs. For example:

```bash
--add-header CustomerId=rZnZzZu9wH --add-header ProcessorVendor=AMD --add-header IsVIP=true
```

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

The download URL of the latest updater executable. Redirects are supported.

### `--path`

The absolute path to the local updater executable.
