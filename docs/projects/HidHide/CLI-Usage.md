# Command Line Interface

!!! important "Topic intended for power users"
    The configuration client is enough for most people. Use `HidHideCLI.exe` when you need scripting, a replayable backup of the current lists, or to hide Xbox / XInput controllers that the GUI cannot cloak reliably.

HidHide ships a command-line client next to the driver and the GUI. It talks to the same control device as the [API](API-Documentation.md) and the configuration client: `\\.\HidHide`. Third-party installers are expected to **extend** a user's lists, not replace them.

## Location and prerequisites

Current installers place the binary at:

```text
%ProgramFiles%\Nefarius Software Solutions\HidHide\HidHideCLI.exe
```

That path is architecture-neutral. Older layouts used an `x64` subdirectory; if `HidHideCLI.exe` is missing at the path above, look one level deeper or reinstall from the [latest release](https://github.com/nefarius/HidHide/releases/latest).

!!! warning "Close the configuration client first"
    Only one process may open `\\.\HidHide` at a time. If the GUI is running, the CLI fails to start. Close **HidHide Configuration Client**, then retry. The same exclusive-handle rule applies the other way around.

The CLI does **not** need elevation. Do not run it from an administrator prompt unless the rest of your script already requires that.

Useful first checks:

```powershell
$cli = Join-Path $env:ProgramFiles 'Nefarius Software Solutions\HidHide\HidHideCLI.exe'
& $cli --version
& $cli --help
```

```cmd
"%ProgramFiles%\Nefarius Software Solutions\HidHide\HidHideCLI.exe" --version
"%ProgramFiles%\Nefarius Software Solutions\HidHide\HidHideCLI.exe" --help
```

`--help` prints every command, its argument syntax, and a reminder that commands can be sequenced on one line.

## Invocation modes

The client picks a mode from the command line and from whether stdin is a console:

| Mode | How you get it | How it ends |
|---|---|---|
| One-shot | Pass one or more command flags (`--cloak-on`, `--dev-hide`, …) | Commands run, then pending changes are written |
| Interactive | Start with no arguments and a real console | Prompt `$ `; ++ctrl+z++ then ++enter++ writes changes and exits |
| Script / piped | Redirect stdin (file, pipe, here-string) | Reads lines until EOF, then writes changes |

Interactive guidance is:

> Type help for options. Press CTRL-Z to save changes and exit. Type Cancel to exit without saving changes.

Commands are the same in every mode. The leading `--` is optional after the parser strips it, but keep it in scripts so the dump commands stay copy-pasteable.

### One-shot

```powershell
& $cli --cloak-state --inv-state --dev-list --app-list
```

Several commands may appear on one invocation. They run in order and share one driver handle, which is the low-overhead form the built-in help refers to.

### Interactive

```powershell
& $cli
```

```text
HidHide command line interface
Type help for options. Press CTRL-Z to save changes and exit. Type Cancel to exit without saving changes.

$ --dev-gaming
$ --dev-hide "HID\VID_054C&PID_0CE6\..."
$ --cloak-on
$
```

Then press ++ctrl+z++ and ++enter++.

### Script / piped

```powershell
@"
--app-reg "C:\Tools\UCR\UCR.exe"
--dev-hide "HID\VID_054C&PID_0CE6\6&1bce44cb&0&0000"
--cloak-on
"@ | & $cli
```

```cmd
HidHideCLI.exe < setup.hidhide
```

A syntax error on a piped or one-shot run prints the message to stderr and **stops without applying** later commands from that line. Interactive mode stays open after an error so you can correct it.

## How changes are applied

The CLI loads the current cloak state, inverse-list flag, device list, and application list when it opens the driver. Most commands edit that in-memory copy. The driver is updated once, when the process exits normally.

That has a few consequences:

- A sequence of `--dev-hide` / `--app-reg` / `--cloak-on` is one batch applied on clean exit. The driver still receives those updates as separate writes, not as an atomic all-or-nothing transaction.
- `--cancel` (interactive: `cancel`) abandons the in-memory copy and skips the write. Use it after a mistake, or append it to a one-shot line if you only wanted to validate arguments.
- `--app-list`, `--dev-list`, `--cloak-state`, and `--inv-state` report the **pending** copy, including edits you have not committed yet.
- The CLI always keeps itself on the application list while inverse cloak is off (and off the list while inverse cloak is on). That self-registration is applied immediately so the tool can still see hidden devices.

!!! tip "Re-enumerate after hiding"
    Updating the lists is not enough for devices that were already plugged in. Unplug and replug, disable/enable the parent node in Device Manager, or reboot. See [I hid my device, but the application can still see it](FAQ.md#i-hid-my-device-but-the-application-can-still-see-it).

## Command reference

Arguments that contain spaces or backslashes must be quoted. Device instance paths and executable paths almost always need quotes.

| Command | Arguments | Effect |
|---|---|---|
| `--help` | none | List commands |
| `--version` | none | Print the client version |
| `--cancel` | none | Exit without writing configuration |
| `--app-list` | none | Print registered applications as `--app-reg` lines |
| `--app-reg` | `"<fully qualified path>"` | Allow that executable to see hidden devices |
| `--app-unreg` | `"<fully qualified path>"` | Remove that executable from the list |
| `--app-clean` | none | Drop list entries whose files no longer exist |
| `--dev-list` | none | Print hidden devices as `--dev-hide` lines |
| `--dev-hide` | `"<device instance path>"` | Add a device instance to the hide list |
| `--dev-unhide` | `"<device instance path>"` | Remove a device instance from the hide list |
| `--dev-gaming` | none | JSON inventory of present gaming HID devices |
| `--dev-all` | none | JSON inventory of all HID devices the client can see |
| `--cloak-on` | none | Enable hiding |
| `--cloak-off` | none | Disable hiding (pass-through) |
| `--cloak-toggle` | none | Flip the current cloak state |
| `--cloak-state` | none | Print `--cloak-on` or `--cloak-off` |
| `--inv-on` | none | Invert the application list |
| `--inv-off` | none | Restore the normal application list |
| `--inv-state` | none | Print `--inv-on` or `--inv-off` |

Reads (`--*-list`, `--*-state`, `--dev-gaming`, `--dev-all`, `--help`, `--version`) do not need a write-out to be useful. Writes stay pending until a clean exit.

### Application list

`--app-reg` and `--app-unreg` take a **fully qualified** executable path (drive letter or volume mount, no relative names). The file name must end in `.exe`, `.com`, or `.bin`. The CLI then converts that path to the DOS device form the driver stores (`\Device\HarddiskVolume3\...`).

```powershell
& $cli --app-reg "C:\Tools\Joystick Gremlin\joystick_gremlin.exe"
& $cli --app-unreg "C:\Tools\Joystick Gremlin\joystick_gremlin.exe"
& $cli --app-list
& $cli --app-clean
```

Validation failures you will see:

| Message | Typical cause |
|---|---|
| `The file name should include a full path.` | Relative path such as `UCR.exe` |
| `The file name should be an executable (.exe, .com, .bin).` | Wrong extension |
| `The file name should be located on a storage volume (volume is case sensitive).` | Volume prefix does not match a mount point; try the exact drive-letter casing Windows reports |

The file does not have to exist at register time. `--app-clean` later removes entries whose image is gone from disk. If you move an `.exe`, register the new location — the driver matches the on-disk image path, not the process name.

### Device list

`--dev-hide` / `--dev-unhide` take a Windows [device instance path](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/device-instance-ids). The CLI does **not** check that the device is currently present, so you can pre-seed Bluetooth or currently unplugged instances. The path must stay under the system device-ID length limit.

```powershell
& $cli --dev-hide "HID\VID_054C&PID_0CE6\6&1bce44cb&0&0000"
& $cli --dev-unhide "HID\VID_054C&PID_0CE6\6&1bce44cb&0&0000"
& $cli --dev-list
```

Adding an entry that is already listed, or removing one that is not, is a no-op.

HidHide cloaks **instance paths**, not VID/PID wildcards. Two identical pads need two `--dev-hide` lines. A pad that appears on USB and Bluetooth needs both instance paths.

### Cloak (global enable)

`--cloak-on` is the CLI equivalent of **Enable device hiding**. `--cloak-off` is pass-through: every application sees every device again, but the lists are kept.

```powershell
& $cli --cloak-on
& $cli --cloak-state
```

### Inverse application list

Leave inverse cloak **off** unless you know you need it.

| Flag | Effect |
|---|---|
| `--inv-off` (default) | Hidden devices are invisible to every process **except** those on the application list |
| `--inv-on` | Hidden devices are invisible **only** to processes on the application list and stay visible to everything else |

The second mode looks like "HidHide does nothing" if you expected games to lose the pad. Confirm with `--inv-state` before debugging anything else.

```powershell
& $cli --inv-off
& $cli --inv-state
```

## Discovering devices

`--dev-gaming` lists HID devices the client considers game controllers. `--dev-all` drops that filter — use it when a vendor used a custom usage page and the pad is missing from the gaming list.

Output is JSON: an array of containers, each with a `friendlyName` and a `devices` array. Typical fields on a device:

| Field | Use |
|---|---|
| `present` | Whether Windows currently has the instance |
| `gamingDevice` | Gaming-usage heuristic |
| `vendor` / `product` / `serialNumber` / `description` / `usage` | Identification |
| `deviceInstancePath` | Path to pass to `--dev-hide` for the HID node |
| `baseContainerDeviceInstancePath` | Parent container, usually `USB\...` — required for XInput |
| `xusbDeviceInstancePath` | Companion XUSB/XInput node when one exists |
| `baseContainerDeviceCount` | How many functions share that container |
| `symbolicLink` | Device interface symlink |

```powershell
& $cli --dev-gaming | Set-Content -Encoding utf8 gaming-hid.json
```

Pick the instance that matches the connection you are about to cloak. Composite devices expose several HID children under one container; hide each child you want gone, and for Xbox / XInput also hide the container itself (see below).

If `--dev-gaming` is an empty array while the pad is plugged in, retry with `--dev-all`, then confirm the configuration client is closed so the CLI can open the driver.

## Hiding Xbox / XInput controllers {#hiding-xbox-xinput-controllers}

The configuration client often marks only the `HID\...` child. That is enough for DirectInput. XInput (Xbox 360, Xbox One, many "XInput compatible" pads, and some virtual Xbox devices) can open the **USB base-container** device instead and walk around the HID cloak.

This is the [known client limitation](https://github.com/nefarius/HidHide/issues/39). The workaround is to hide **both** instance paths through the CLI.

1. Close HidHide Configuration Client.
2. Plug the controller in the way you will use it (USB or wireless dongle). Repeat the procedure later for the other transport if it has one.
3. Inventory the device:

    ```powershell
    & $cli --dev-gaming
    ```

4. From the matching object, copy `deviceInstancePath` (starts with `HID\`) and `baseContainerDeviceInstancePath` (starts with `USB\`). If `xusbDeviceInstancePath` is non-empty, hide that too.
5. Apply both (or all three) hides and turn cloaking on:

    ```powershell
    & $cli `
      --dev-hide "HID\VID_045E&PID_028E\6&abcdef01&0&0000" `
      --dev-hide "USB\VID_045E&PID_028E\5&12345678&0&1" `
      --cloak-on
    ```

6. Confirm the pending list:

    ```powershell
    & $cli --dev-list --cloak-state
    ```

    You should see a `--dev-hide` line for every instance you added and `--cloak-on`.
7. Reconnect the controller or rebuild the parent stack so the filter attaches. Then test with `joy.cpl` and with a game that uses XInput.

!!! warning "Do not hide only the USB node on a generic HID device"
    USB-instance hiding is the XInput workaround. A regular DirectInput joystick, wheel, or HOTAS is cloaked by its `HID\...` path. Hiding a random `USB\VID_...` parent can take out every function of that composite device.

Device Manager can supply the same two paths if JSON output is awkward: switch **View** to **Devices by container**, select the Xbox pad, then **View → Devices by connection** and expand it. The HID child and the USB parent are the two instance paths `--dev-hide` needs. After an interactive session, ++ctrl+z++ then ++enter++ commits; then reconnect.

## Inspecting, backing up, and restoring

List commands print **replayable** CLI text, not a private dump format:

```text
--app-reg "C:\Tools\UCR\UCR.exe"
--dev-hide "HID\VID_054C&PID_0CE6\6&1bce44cb&0&0000"
--cloak-on
--inv-off
```

Capture a snapshot:

```powershell
& $cli --inv-state --cloak-state --dev-list --app-list |
  Set-Content -Encoding utf8 hidhide-backup.txt
```

Restore by feeding that file back in (after reviewing it — do not blindly wipe another tool's entries):

```powershell
Get-Content hidhide-backup.txt | & $cli
```

`--dev-hide` and `--app-reg` merge into the existing sets. They do not clear unrelated entries. If you need a device or application gone, `--dev-unhide` / `--app-unreg` that path explicitly.

## End-to-end recipes

### Remap a generic pad and hide it from games

```powershell
$cli = Join-Path $env:ProgramFiles 'Nefarius Software Solutions\HidHide\HidHideCLI.exe'
$remap = 'C:\Tools\UCR\UCR.exe'

& $cli --dev-gaming   # copy the HID instance path of the real pad

& $cli `
  --inv-off `
  --app-reg $remap `
  --dev-hide "HID\VID_0810&PID_0001\6&aabbccdd&0&0000" `
  --cloak-on
```

Reconnect the pad. The remapper should still see it; `joy.cpl` and games should not.

### Cloak an Xbox pad that the GUI could not hide

Follow [Hiding Xbox / XInput controllers](#hiding-xbox-xinput-controllers). The important part is both `HID\...` and `USB\...` on the hide list, then a stack rebuild.

### Temporarily disable hiding without losing the lists

```powershell
& $cli --cloak-off
```

Turn it back on with `--cloak-on`. Lists stay as they were.

### Drop stale application entries after moving tools

```powershell
& $cli --app-clean --app-list
```

### Dry-run a command line

```powershell
& $cli --dev-hide "HID\VID_054C&PID_0CE6\6&1bce44cb&0&0000" --cancel
```

The path is validated. `--cancel` discards the staged hide and skips the exit-time write; it does not undo the CLI's immediate self-whitelist adjustment.

## Errors, exit codes, and quoting

On success the process exits `0`. Failures (driver not found, access denied because the GUI holds the handle, unhandled exceptions) print to stderr and return a Win32 status.

Parser messages:

| Message | Meaning |
|---|---|
| `The syntax of this command is not correct.` | Unbalanced quotes or leftover text the parser could not split |
| `The command is not recognized.` | Unknown verb |
| `The number of command arguments is not correct.` | Extra or missing argument |
| `The device instance path has too many characters.` | Path exceeds `MAX_DEVICE_ID_LEN` |

PowerShell passes `--dev-hide` and similar flags to a native executable as ordinary arguments. Use `--%` only when you need to stop PowerShell from parsing the rest of the line (for example, so `&` inside a hardware ID is not treated as a call operator):

```powershell
& $cli --% --dev-hide "HID\VID_054C&PID_0CE6\6&1bce44cb&0&0000" --cloak-on
```

Or call through `cmd.exe /c`. Always quote instance paths.

## Automation notes

- Add commands are idempotent: registering the same app or hiding the same instance twice is safe. `--cloak-toggle` flips state on every invocation; retryable scripts should use `--cloak-on` or `--cloak-off`.
- Do **not** treat the configuration as yours alone. Feeder apps may whitelist themselves through the [public API](API-Documentation.md). Prefer add/remove of the entries you own.
- Kaspersky can break process matching for the application list; that is independent of the CLI. See the note on the [HidHide overview](index.md).
- Inverse cloak, Raw Input, and mice/keyboards are still out of scope — the [FAQ](FAQ.md) covers those limits.
- After a scripted change, rebuild the device stack before declaring success.

## Related

- [Simple setup guide](Simple-Setup-Guide.md) — GUI walkthrough
- [FAQ](FAQ.md) — stack rebuild, inverse cloak, Xbox client limitation
- [API documentation](API-Documentation.md) — IOCTL contract used by this CLI
- [HidHideCLI source](https://github.com/nefarius/HidHide/tree/master/HidHideCLI)
