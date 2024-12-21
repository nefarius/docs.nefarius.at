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

### `--override-success-code <code>`

Can be used in conjunction with the [`--install`](#-install) and [`--uninstall`](#-uninstall) switch to override the default success exit code with the user-specified value. Useful if the calling process can not be configured to treat any other value than e.g. 0 as a success.

### `--uninstall`

Removes the autostart registration and deletes the scheduled task job. The process will exit after these tasks finished successfully or on error.

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

In versions above v1.8.876, therei s no validation of this parameter; server-side validation is assumed to be sufficient.

In v1.8.876 and below, the value can be any alphanumeric string **excluding** the following characters:

- `'/'` (forward slash)
- `'\'` (backslash)
- `' '`&nbsp;(space)
- `.` (period)
- `2` (the number 2)

Server-side path validation should still be used with earlier versions of the client.

### `--add-header <name=value>`

Allows for adding one or more additional HTTP headers to be added to the update server request. This can be used in conjunction with a backend application server to influence delivery of the [remote configuration](Remote-Configuration.md) based on certain custom client parameters.

This parameter can be specified multiple times with different name-value-pairs. For example:

```bash
--add-header CustomerId=rZnZzZu9wH --add-header ProcessorVendor=AMD --add-header IsVIP=true
```

### `--ignore-postpone`

Ignores the check if we are in an active postpone period, if specified. Does nothing if there is no active postpone period.

### `--purge-postpone`

Deletes the registry-backed postpone data, if present.

### `--terminate-process-before-update <handle>`

An optional [handle](https://learn.microsoft.com/en-us/windows/win32/sysinfo/about-handles-and-objects) to a process object to terminate before the update starts. See [this article](Terminate-Process-before-Update.md) for details.

### `--local-version <version>`

Overrides the [detected local product version](Product-Detection.md) if no detection method was specified in either the local or server-provided configuration.

### `--force-local-version <version>`

Overrides the [detected local product version](Product-Detection.md). This value trumps any product detection method specified in either local or server-provided configuration.

## Internal

!!! warning "Beware of altering"
    The following arguments are set or removed by other [common](#common) commands and should not be altered by the user.

### `--autostart`

Performs tasks on user logon like checking self-integrity and searching for updates.

### `--background`

Tells the updater it's run by Task Scheduler. It will not display any UI except when an update has been found. Errors will be logged but the user will not be actively notified.

### `--temporary`

Tells the updater it's run as a temporary child process to avoid blocking an in-progress setup procedure by locking the origin file. If this flag is present, certain commands (like `--install`) are ignored.

## Self-Updater

The following parameters are passed from the main updater process to the self-updater module.

They can not be altered by the user.

### `--pid`

The Process ID of the parent updater process that invoked the self-update module.

### `--url`

The download URL of the latest updater executable. Redirects are supported.

### `--path`

The absolute path to the local updater executable.
