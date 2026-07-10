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
`209` | The watched product was still running after the maximum wait period ([`productBusyDetection`](Local-Configuration.md#productbusydetection)); nothing was shown or installed. The next scheduled or logon invocation will retry. Also returned when a logoff or shutdown arrives during the wait.

!!! note "Exit code 208 is reserved"
    `208` (`NV_S_CLOSED_WHILE_UPDATER_RUNNING`) is defined as a constant but is not currently returned as a process exit code. It is used internally as a setup-task result sentinel. Setups that are interrupted due to user cancellation or process exit report via `109` instead.

## Error conditions

Code | Description
---|---
`100` | Failed to parse [command line arguments](Command-Line-Arguments.md).
`101` | Failed to register autostart entry.
`102` | Failed to (re-)create scheduled task.
`103` | Failed to extract self-updater component.
`104` | Failed to request or process the update server response. Also returned when the manifest Ed25519 signature is invalid or the manifest `.minisig` sidecar could not be fetched, or when a manifest version rollback is detected (see [Signature Verification](Signature-Verification.md)).
`105` | Failed to detect installed product version.
`106` | The user session is currently busy (e.g. a full-screen game or presentation is running) and the updater is running in a silent mode. This check is only performed in silent runs (`--background`, `--autostart`, `--silent`, `--silent-update`); interactive runs always show the window regardless of session state.
`107` | The release download failed (network error, timeout, or all retries exhausted).
`108` | The setup process could not be launched (e.g. the downloaded file is missing or cannot be executed).
`109` | The setup process exited with a non-success exit code, or a setup launch/extraction error occurred. Also returned when the `--terminate-process-before-update` call fails (see below).
`110` | The [`--purge-postpone`](Command-Line-Arguments.md#-purge-postpone) command encountered a registry error. An empty or absent postpone entry is not an error — the command exits `206` in that case.
`112` | Two or more specified [command line arguments](Command-Line-Arguments.md) were incompatible with each other. Currently this only occurs when `--temporary` is combined with any silent-mode flag (`--silent`, `--background`, `--autostart`, or `--silent-update`).
`113` | The updater file name contains some invalid sequences.
`114` | Failed to create the Direct3D 11 rendering device (display driver issue or insufficient GPU).
`116` | A post-download integrity or authenticity check failed. This covers all of: checksum mismatch, invalid or untrusted Authenticode chain, publisher certificate not matching the configured pin, and (when `--strict-verification` is active) a release that lacks a required `checksum` field. See [Signature Verification](Signature-Verification.md) and [Download Integrity](Download-Integrity.md).

!!! note "Reserved / not yet individually emitted"
    The following codes are defined in the source but currently all map to `116` (post-download) or `104` (manifest) or `109` (terminate-process) at runtime:

    Code | Reserved meaning
    ---|---
    `111` | Failed to terminate the process specified via [`--terminate-process-before-update`](Command-Line-Arguments.md#-terminate-process-before-update-handle). Currently reported as `109`.
    `115` | Checksum mismatch (download hash differs from expected value). Currently reported as `116`.
    `117` | Publisher certificate does not match the configured pin. Currently reported as `116`.
    `118` | Manifest Ed25519 signature invalid or sidecar not fetchable. Currently reported as `104`.
    `119` | Manifest version rollback detected. Currently reported as `104`.
