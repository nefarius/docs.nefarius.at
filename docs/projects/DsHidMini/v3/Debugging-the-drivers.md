# Debugging the Drivers

Kernel and user-mode drivers do not write log files to disk. Instead they use [Event Tracing for Windows](https://docs.microsoft.com/en-us/windows-hardware/test/wpt/event-tracing-for-windows) (ETW), which you capture from the command line using `etwutils`.

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

## Make sure you are on the latest v3.x release

!!! warning "Update before capturing"
    The `etwutils` capture commands below use the **Nefarius public symbol server** to automatically download the PDB file that matches your installed driver. If your DsHidMini installation is outdated or mismatched, symbol resolution will fail and every event will appear as a meaningless `GUID=...` placeholder — making the trace useless.

    **Before proceeding**, make sure you have the latest v3.x release installed. Head to the [DsHidMini releases page](https://github.com/nefarius/DsHidMini/releases) and follow the [installation guide](How-to-Install.md) if you need to update.

## Enable verbose tracing

By default, verbose tracing is **off**. You need to enable it once by importing a registry file and then rebooting.

1. Download and run [dshidmini_debug.reg](https://github.com/nefarius/DsHidMini/raw/8a9ee4de113ceece04c66314140db991fe2651d2/debugging/dshidmini_debug.reg) — double-click it and confirm all message boxes.

2. **Reboot** the machine before continuing.

!!! tip "Alternative: enable via etwutils"
    Instead of the `.reg` file, you can enable verbose tracing from an **Administrator** PowerShell with a single command:

    !!! example "PowerShell (as Administrator)"
        ```PowerShell
        etwutils verbose dshidmini enable --type umdf
        ```

    Either approach has the same effect. You only need to do this **once** — later trace sessions do not require another reboot or re-import.

## Step 1 — Quick live test (validate decoding first)

Before capturing to a file, confirm that the setup is working and that events are properly decoded.

In an **Administrator** PowerShell, run:

!!! example "PowerShell (as Administrator)"
    ```PowerShell
    etwutils realtime --driver dshidmini --symbol-server https://symbols.nefarius.at/download/symbols --format plain
    ```

On first run `etwutils` will download the matching `dshidmini.pdb` from the Nefarius symbol server and cache it locally — subsequent runs start immediately from cache.

Now plug in your DS3 controller. You should see human-readable lines scrolling in the terminal similar to:

```text
2026-05-26T14:51:23.1234567+02:00    DsHidMiniTraceGuid    TRACE_LEVEL_INFORMATION    Device arrived: USB\VID_054C&PID_0268
2026-05-26T14:51:23.5678901+02:00    DsHidMiniTraceGuid    TRACE_LEVEL_VERBOSE          ConnectRequest: handle=0x0003
```

!!! warning "Do not continue if you see GUID placeholders or no output"
    If the terminal shows lines like `GUID={xxxxxxxx-...}` instead of a friendly provider name and readable messages, symbol resolution failed. Go back and verify your DsHidMini installation is up to date.

    If you see **no output at all** after plugging in the controller, verbose tracing may not have been enabled yet — confirm you ran the `.reg` import (or `etwutils verbose`) and rebooted.

    **Only continue to Step 2 once you see properly decoded events here.** Take a screenshot of this output to share if you are reporting an issue.

When you are done confirming, press ++ctrl+c++ to stop the session.

## Step 2 — Capture a trace to a file

Once Step 1 shows correctly decoded events, stop the live session (++ctrl+c++) and run the same command redirected to a file:

!!! example "PowerShell (as Administrator)"
    ```PowerShell
    etwutils realtime --driver dshidmini --symbol-server https://symbols.nefarius.at/download/symbols --format plain --color never > C:\TEMP\events.tsv
    ```

Leave the terminal open and reproduce the problem you are trying to investigate. Once you have captured the relevant behaviour, press ++ctrl+c++ to end the capture.

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
