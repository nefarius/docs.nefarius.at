# Setup Exit Code Handling

When the updater runs the downloaded setup process, it captures the exit code the setup returns and decides whether the installation succeeded or failed. By default only exit code `0` is treated as success.

!!! note "ZIP archive updates bypass exit code checking"
    For ZIP-based updates the updater performs file copy operations directly and does not launch an external setup executable. Success is determined by whether the extraction and copy succeeded, not by an exit code. The `exitCode` configuration has no effect on ZIP updates.

!!! note "Setup launch failures"
    If the setup process cannot be launched at all (e.g. the downloaded file is missing or not executable), the updater exits with code `109` (`NV_E_SETUP_FAILED`) rather than consulting the exit-code configuration.

The `exitCode` object in the [remote configuration](Remote-Configuration.md) lets you control this behaviour. It can be placed either on the `instance` object (applies to every release) or directly on an individual release entry (takes precedence over the instance-level setting when both are present).

## Basic fields

Field | Type | Default | Description
---|---|---|---
`skipCheck` | `bool` | `false` | When `true`, the updater ignores whatever exit code the setup returns and always considers the installation successful.
`successCodes` | `int[]` | `[0]` | List of exit codes accepted as success. Any code in this list causes the updater to treat the installation as having succeeded.

!!! example "Accept both plain success (0) and MSI reboot-required (3010)"

    ```json
    {
        "releases": [{
            "exitCode": {
                "successCodes": [0, 3010]
            }
        }]
    }
    ```

## Exit code message map (`messages`)

The `messages` field is an object whose **keys are exit codes expressed as decimal strings** (e.g. `"3010"`) and whose values are message entries. It lets you:

- Attach a human-readable message shown to the user in the updater UI.
- Optionally display a help button that opens a URL.
- Optionally promote the code to a success condition without listing it in `successCodes` a second time.

### Message entry fields

Field | Type | Required | Description
---|---|---|---
`message` | `string` | Yes | Text shown to the user when this exit code is encountered. An empty string (`""`) is treated the same as no entry — no custom screen is shown and the updater falls back to default behavior (success closes silently; failure shows the generic error text).
`isSuccess` | `bool` | No | When `true`, this exit code is treated as a success condition even if it is absent from `successCodes`.
`helpUrl` | `string` | No | URL opened in the browser when the user clicks the help button shown alongside the message.
`buttonText` | `string` | No | Custom label for the help button. Defaults to `"Open help page"` when omitted.

### UI behaviour

**Success path** — when the setup exits with a code that resolves to success (via `skipCheck`, `successCodes`, or `isSuccess: true` in the map) and a `messages` entry exists for that code, the updater displays a success screen with the configured message text and an optional help button. The user must click **Finish** to close the updater. Without a message entry the updater closes silently, as it always has.

**Failure path** — when the setup exits with a non-success code and a `messages` entry exists for it, the updater shows the distributor-supplied message and optional help button instead of the generic "unexpected exit code" text, allowing you to provide more actionable guidance for known failure modes.

## Examples

### Reboot required after MSI installation

MSI installers exit with `3010` (`ERROR_SUCCESS_REBOOT_REQUIRED`) when the installation succeeded but a reboot must be completed before the new version is active. Without configuration the updater either treats this as a plain success (if `3010` is in `successCodes`) or as a failure. With a message entry you can inform the user precisely why a restart is needed.

```json
{
    "releases": [{
        "exitCode": {
            "successCodes": [0],
            "messages": {
                "3010": {
                    "isSuccess": true,
                    "message": "The update was installed successfully. A system reboot is required before the new version becomes active. Please save your work and restart Windows at your earliest convenience.",
                    "helpUrl": "https://docs.example.com/app/update-reboot",
                    "buttonText": "Learn more about the reboot requirement"
                }
            }
        }
    }]
}
```

Because `isSuccess` is `true` on the `"3010"` entry, the code does not also need to appear in `successCodes`.

### User cancelled the installer (MSI exit code 1602)

MSI returns `1602` (`ERROR_INSTALL_USEREXIT`) when the user clicks **Cancel** in the installer UI. Without configuration the updater shows a generic "unexpected exit code" error. A message entry lets you explain clearly that no changes were made and the user can simply retry.

```json
{
    "releases": [{
        "exitCode": {
            "successCodes": [0],
            "messages": {
                "1602": {
                    "message": "The installation was cancelled before it could complete. No changes have been made to your system.\n\nYou can retry the update at any time by running the updater again."
                }
            }
        }
    }]
}
```

### Custom message for a known failure code

```json
{
    "releases": [{
        "exitCode": {
            "successCodes": [0],
            "messages": {
                "1603": {
                    "message": "A fatal error occurred during installation. This is often caused by another installer running in the background. Please close all other installers and try again.",
                    "helpUrl": "https://docs.example.com/app/install-error-1603",
                    "buttonText": "Troubleshooting guide"
                }
            }
        }
    }]
}
```

### Instance-level defaults

Place the `exitCode` object on `instance` to apply the same settings to all releases at once:

```json
{
    "instance": {
        "exitCode": {
            "successCodes": [0, 3010],
            "messages": {
                "3010": {
                    "isSuccess": true,
                    "message": "Installation succeeded. Please restart Windows to complete the update."
                }
            }
        }
    },
    "releases": [...]
}
```

A release-level `exitCode` always takes precedence over the instance-level one when both are present.
