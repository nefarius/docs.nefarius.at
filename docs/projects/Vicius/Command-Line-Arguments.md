# Command Line Arguments

## `--install`

Typically called with only once when the bundled product gets installed. Performs self-registration in current users' autostart and daily runs via Task Scheduler. Errors will be logged but the user will not be actively notified. Check the exit code for potential error cases.

## `--uninstall`

Removes the autostart registration and deletes the scheduled task job.

## `--autostart`

Performs tasks on user logon like checking self-integrity and searching for updates.

## `--background`

Tells the updater it's run by Task Scheduler. It will not display any UI except when an update has been found. Errors will be logged but the user will not be actively notified.

## `--log-level <value>`

Alters the default logging level (`info`) to the provided `<value>`.

Possible values are: `trace`, `debug`, `info`, `warn`, `err`, `critical` or `off`.
