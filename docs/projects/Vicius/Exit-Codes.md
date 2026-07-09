# Possible Exit Codes

Various success or error states can be inferred from the process exit code.

## Success states

!!! note "Can be overridden"
    Some of those can be overridden with [`--override-success-code` switch](Command-Line-Arguments.md#-override-success-code-code).

Code | Description
---|---
`200` | The [`--install`](Command-Line-Arguments.md#-install)/[`--uninstall`](Command-Line-Arguments.md#-uninstall) command finished successfully.
`201` | The self-updater process started successfully.
`202` | The installed product is up to date.
`203` | The update got installed successfully.
`204` | The user chose to postpone the update right now.
`205` | The user postponed the update and 24 hours since then haven't yet passed.
`206` | The [`--purge-postpone`](Command-Line-Arguments.md#-purge-postpone) command finished successfully.
`207` | A new updater process was successfully created from a temporary location.
`208` | The updater process was closed while a setup operation was still in progress.
`209` | The watched product was still running after the maximum wait period ([`productBusyDetection`](Local-Configuration.md#productbusydetection)); nothing was shown or installed. The next scheduled or logon invocation will retry.

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
`110` | The [`--purge-postpone`](Command-Line-Arguments.md#-purge-postpone) command didn't succeed. There might be no active postpone period.
`111` | Failed to terminate the process specified via [`--terminate-process-before-update`](Command-Line-Arguments.md#-terminate-process-before-update-handle).
`112` | Two or more specified [command line arguments](Command-Line-Arguments.md) were incompatible with each other.
`113` | The updater file name contains some invalid sequences.
`114` | Failed to create the Direct3D 11 rendering device (display driver issue or insufficient GPU).
`115` | Checksum failure — either the release was rejected before download because it lacks a `checksum` field when [`--strict-verification`](Command-Line-Arguments.md#--strict-verification) is active, or the computed hash of the downloaded file does not match the expected value. See [Download Integrity](Download-Integrity.md).
`116` | Setup Authenticode signature is invalid or the chain could not be validated. See [Signature Verification](Signature-Verification.md).
`117` | Publisher certificate does not match the configured pin. See [Signature Verification](Signature-Verification.md).
`118` | Manifest Ed25519 signature is invalid or the `.minisig` sidecar could not be fetched. See [Signature Verification](Signature-Verification.md).
`119` | Manifest version rollback detected — the server delivered an older manifest version. See [Signature Verification](Signature-Verification.md).
