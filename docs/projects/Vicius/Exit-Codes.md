# Possible Exit Codes

Various success or error states can be inferred from the process exit code.

## Success states

Code | Description
---|---
`200` | The `--install` command finished successfully.
`201` | The self-updater process started successfully.
`202` | The installed product is up to date.
`203` | The update got installed successfully.

## Error conditions

Code | Description
---|---
`100` | Failed to parse [command line arguments](Command-Line-Arguments.md).
`101` | Failed to register autostart entry.
`102` | Failed to (re-)create scheduled task.
`103` | Failed to extract self-updater component.
`104` | Failed to request or process update server response.
`105` | Failed to detect installed product version.
`106` | The user is currently running a game or other full-screen applications.