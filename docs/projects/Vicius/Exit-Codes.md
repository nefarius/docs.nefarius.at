# Possible Exit Codes

Various success or error states can be inferred from the process exit code.

## Success states

!!! note "Can be overridden"
   Some of those can be overridden with [`--override-success-code-code` switch](Command-Line-Arguments.md#-override-success-code-code).

Code | Description
---|---
`200` | The [`--install`](Command-Line-Arguments.md#-install)/[`--uninstall`](Command-Line-Arguments.md#-uninstall) command finished successfully.
`201` | The self-updater process started successfully.
`202` | The installed product is up to date.
`203` | The update got installed successfully.
`204` | The user chose to postpone the update right now.
`205` | The user postponed the update and 24 hours since then haven't yet passed.

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
`107` | The release download failed and the user aborted the update.
`108` | The setup launch failed and the user aborted the update.
`109` | The setup execution finished with a non-success exit code and the user aborted the update.
