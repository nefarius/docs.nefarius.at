# Debugging the Drivers

Kernel drivers do not write normal log files to disk. Instead they use [Event Tracing for Windows](https://docs.microsoft.com/en-us/windows-hardware/test/wpt/event-tracing-for-windows) (ETW), which you capture from the command line using `etwutils`.

BthPS3 ships instrumentation manifests (`BthPS3.man`, `BthPS3PSM.man`) for structured events. Verbose WPP-style tracing below is still **off** until you enable it once.

## Prerequisites

### Install the .NET SDK

`etwutils` is a .NET global tool and requires the **.NET 8, 9, or 10 SDK** (not the runtime-only install) on Windows.

Download it from [dot.net](https://dot.net) and run the installer. Once done, open a new terminal and verify:

!!! example "PowerShell"
    ```PowerShell
    dotnet --version
    ```

### Install etwutils

!!! warning "Administrator required"
    ETW session creation requires an elevated process. Open **PowerShell as Administrator** for all commands in this guide (press ++win+x++ and choose it from the menu).

!!! example "PowerShell (as Administrator)"
    ```PowerShell
    dotnet tool install -g Nefarius.Utilities.ETW.CLI
    ```

This makes the `etwutils` command available on your `PATH`. For full installation details see the [etwutils README](https://github.com/nefarius/Nefarius.Utilities.ETW/blob/master/tools/Nefarius.Utilities.ETW.CLI/README.md#installation).

## Make sure you are on the latest release

!!! warning "Update before capturing"
    The `etwutils` capture commands below use the **Nefarius public symbol server** to automatically download the PDB files that match your installed drivers. If your BthPS3 installation is outdated or mismatched, symbol resolution will fail and every event will appear as a meaningless `GUID=...` placeholder — making the trace useless.

    **Before proceeding**, make sure you have the latest published installer. Head to the [BthPS3 releases page](https://github.com/nefarius/BthPS3/releases) and follow the [installation guide](How-to-Install.md) if you need to update.

## Enable verbose tracing

By default, verbose tracing is **off**. Enable it once for both kernel services, then reboot.

1. In an **Administrator** PowerShell, run:

    !!! example "PowerShell (as Administrator)"
        ```PowerShell
        etwutils verbose BthPS3 enable
        etwutils verbose BthPS3PSM enable
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\BthPS3\Parameters\Wdf" -Name "VerboseOn" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\BthPS3PSM\Parameters\Wdf" -Name "VerboseOn" -Type DWord -Value 1 -Force
        ```

    `etwutils verbose` turns on driver WPP output. The two `Parameters\Wdf` values add verbose Windows Driver Framework logs for the same services.

2. **Reboot** the machine before continuing.

You only need to do this **once** — later trace sessions do not require another reboot.

## Step 1 — Quick live test (validate decoding first)

Before capturing to a file, confirm that the setup is working and that events are properly decoded.

In an **Administrator** PowerShell, run:

!!! example "PowerShell (as Administrator)"
    ```PowerShell
    etwutils realtime --driver BthPS3 --driver BthPS3PSM --symbol-server https://symbols.nefarius.at/download/symbols --format plain
    ```

On first run `etwutils` will download the matching `BthPS3.pdb` and `BthPS3PSM.pdb` from the Nefarius symbol server and cache them locally — subsequent runs start immediately from cache.

Now reproduce a Bluetooth action, for example press the PS button so the pad tries to connect. You should see human-readable lines scrolling in the terminal similar to:

```text
2026-05-26T14:51:23.1234567+02:00    BthPS3TraceGuid       TRACE_LEVEL_INFORMATION    RemoteConnectReceived
2026-05-26T14:51:23.5678901+02:00    BthPS3PSMTraceGuid    TRACE_LEVEL_VERBOSE          PsmPatchActivity
```

!!! warning "Do not continue if you see GUID placeholders or no output"
    If the terminal shows lines like `GUID={xxxxxxxx-...}` instead of a friendly provider name and readable messages, symbol resolution failed. Go back and verify your BthPS3 installation is up to date.

    If you see **no output at all** after trying to connect, verbose tracing may not have been enabled yet — confirm you ran the commands above and rebooted.

    **Only continue to Step 2 once you see properly decoded events here.** Take a screenshot of this output to share if you are reporting an issue.

When you are done confirming, press ++ctrl+c++ to stop the session.

## Step 2 — Capture a trace to a file

Once Step 1 shows correctly decoded events, stop the live session (++ctrl+c++) and run the same command redirected to a file:

!!! example "PowerShell (as Administrator)"
    ```PowerShell
    etwutils realtime --driver BthPS3 --driver BthPS3PSM --symbol-server https://symbols.nefarius.at/download/symbols --format plain --color never > C:\TEMP\events.tsv
    ```

Leave the terminal open and reproduce the behaviour you want to investigate. For example:

- **Controller not connecting over Bluetooth:** Try connecting it several times (turn on with the PS button, wait until the LEDs stop blinking, then try again).
- **Controller turning off randomly:** Use the controller until it disconnects on its own.
- **Something works over USB but not Bluetooth (e.g. LEDs, rumble, sticks):** Repeat the same actions over Bluetooth that work over USB.

Once you have captured the relevant behaviour, press ++ctrl+c++ to end the capture.

The resulting `events.tsv` file can be quite large. Compress it with [7-Zip](https://www.7-zip.org/) or WinRAR before sharing it.

!!! note "Trace file contents"
    The trace file may contain device identifiers needed for debugging. Share it securely and only with trusted recipients.

## Troubleshooting

### Session resource error

If `etwutils` exits immediately with a resource or access error, a previous session may not have been cleaned up (e.g. after closing the terminal without pressing ++ctrl+c++). Clean up any leftover sessions with:

!!! example "PowerShell (as Administrator)"
    ```PowerShell
    etwutils sessions clean
    ```

Then try the capture command again.

## Interpreting the trace

Once the trace is decoded, look for `TRACE_LEVEL_WARNING` or `TRACE_LEVEL_ERROR` entries. These indicate driver failures and can point to the cause of connection or behaviour issues. Whether the issue can be fixed depends on the specific message and your setup.

Also look at the structured events below. **BthPS3 v3.1** and **v3.2** added correlatable events for PSM registration, remote connect, filter initialization, and BTHX transport. They show up in the same decoded output once symbols (or the installed manifests) are applied.

## Interpreting common events

These names come from the shipped manifests (`BthPS3.man`, `BthPS3PSM.man`). You do not need every line; use the table to tell expected noise from a real failure.

### Profile driver (`BthPS3`)

| Event | What it means |
| --- | --- |
| `RemoteConnectReceived` | An inbound L2CAP connect reached the profile driver (address + PSM). |
| `PsmRegistrationSucceeded` / `PsmRegistrationFailed` | HID Control / Interrupt PSM listen was registered or failed. A failure here means PS3 peripherals cannot connect. |
| `PsmRegistrationStale` / `PsmRegistrationDeferred` / `PsmRegistrationRecovered` | A previous listen was still committed; the driver reclaims it and retries. Recovery is success. |
| `RemoteDeviceName` / `RemoteDeviceIdentified` / `RemoteDeviceNotIdentified` | The remote Bluetooth name was read and matched (or not) against the supported-name lists. An empty name followed by "not identified or denied" is a firmware/radio problem on the pad. See [The controller tries to connect, then BthPS3 drops it](Frequently-Asked-Questions.md#the-controller-tries-to-connect-then-bthps3-drops-it). |
| `HidControlChannelConnected` / `HidInterruptChannelConnected` / `HidChannelConnectedDetailed` | The two HID channels came up. |
| `RemoteDeviceOnline` | Both channels are up; the pad is ready. |
| `RemoteDisconnectCompleted` / `RemoteL2capDisconnected` | The remote went away (status or channel). |
| `PowerPolicyIdleSettingsFailed` | **Informational.** Idle settings were left unchanged because BthPS3 does not own the device power policy and the device is not in RAW mode. **This is expected when DsHidMini is installed.** It is not a failure. |
| `WdfDeviceAssignS0IdleSettingsFailed` | A real power-policy assignment error (different from the informational skip above). |

### Filter driver (`BthPS3PSM`)

| Event | What it means |
| --- | --- |
| `TransportTypeDetected` | The radio was classified as USB (`1`) or BTHX (`2`). |
| `FilterDeviceInitialized` | Filter init succeeded for that instance (transport, patch status, NTSTATUS). Logged only on success. |
| `PsmPatchActivity` / `PsmPatchActivityDetailed` | An L2CAP connection request was seen and optionally rewritten. Use these when PSM patching looks off. |
| `UnsupportedTransportType` | The radio is neither USB nor BTHX; the filter will not attach. Matches [setup error 9004](Frequently-Asked-Questions.md#how-do-i-fix-setup-error-9004). |
| `BthxAclDataRejected` | A BTHX ACL completion reported an implausible length. Host-stack / radio noise; collect the trace if it repeats around a failed connect. |
| `FailedToFindBulkInPipe` / `HookSendFailed` | The USB or BTHX hook could not be installed or a hooked send failed. Patching will not work until this is resolved. |

!!! note "PSM patching and traces"
    Filter options in the [Driver Configuration Utility](Driver-Configuration-Utility-Explained.md#enable-psm-patching) are what you change; these events are how you confirm the filter actually saw and rewrote a connect.
