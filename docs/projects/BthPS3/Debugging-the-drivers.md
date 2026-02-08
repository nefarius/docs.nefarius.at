# Debugging the Drivers

Kernel drivers do not write normal log files to disk. Instead, they use [Event Tracing for Windows](https://docs.microsoft.com/en-us/windows-hardware/test/wpt/event-tracing-for-windows) (ETW), which you can capture from the command line.

## Prepare verbose tracing

1. Open **PowerShell as Administrator** (press ++win+x++ and choose it from the menu):

    ![Start PowerShell](../../images/Y2bzZWdYK4.png)

    Keep this window open; you will use it for the following steps.

2. By default, verbose tracing is **off**. To enable it, run these commands in PowerShell:

    !!! example "PowerShell"
        ```PowerShell
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\BthPS3\Parameters" -Name "VerboseOn" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\BthPS3\Parameters\Wdf" -Name "VerboseOn" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\BthPS3PSM\Parameters" -Name "VerboseOn" -Type DWord -Value 1 -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\BthPS3PSM\Parameters\Wdf" -Name "VerboseOn" -Type DWord -Value 1 -Force
        ```

3. **Reboot** the machine before continuing.

You only need to do this once; later trace sessions do not require another reboot.

## Capture the trace

### Start trace session

In PowerShell (as Administrator), run these three commands:

!!! example "PowerShell"
    ```PowerShell
    New-EtwTraceSession -Name BthPS3 -LogFileMode 0x8100 -FlushTimer 1 -LocalFilePath "C:\BthPS3.etl"
    Add-EtwTraceProvider -SessionName BthPS3 -Guid '{37dcd579-e844-4c80-9c8b-a10850b6fac6}' -MatchAnyKeyword 0x0FFFFFFFFFFFFFFF -Level 0xFF -Property 0x40
    Add-EtwTraceProvider -SessionName BthPS3 -Guid '{586aa8b1-53a6-404f-9b3e-14483e514a2c}' -MatchAnyKeyword 0x0FFFFFFFFFFFFFFF -Level 0xFF -Property 0x40
    ```

The output should look similar to this (it may differ on your system):

![PowerShell](../../images/35cnHUOIwv.png)

### Reproduce the behaviour you want to capture

While the trace is running, perform the actions you want to investigate. For example:

- **Controller not connecting over Bluetooth:** Try connecting it several times (turn on with the PS button, wait until the LEDs stop blinking, then try again).
- **Controller turning off randomly:** Use the controller until it disconnects on its own.
- **Something works over USB but not Bluetooth (e.g. LEDs, rumble, sticks):** Repeat the same actions over Bluetooth that work over USB.

### Stop the trace session

When you have captured enough, stop the session so the log file is closed:

!!! example "PowerShell"
    ```PowerShell
    Remove-EtwTraceSession -Name BthPS3
    ```

The log file will be at `C:\BthPS3.etl`:

![Trace file location](../../images/AnyDesk_LVe8LzooAQ.png)

## What to do with the trace file

You now have a `BthPS3.etl` file. You can submit it (compressed with WinRAR or 7-Zip) to Nefarius for analysis, or inspect it yourself as described below.

!!! note "Trace file contents"
    The trace file may contain device identifiers needed for debugging. Share it securely with trusted recipients only.

## Decoding the trace file

Trace files are not plain text. You need a tool that can decode ETW content. Microsoft provides such tools, but they are verbose and not very beginner-friendly; a third-party tool is recommended.

### Using MGTEK TraceView Plus 3

1. Download and install [MGTEK TraceView Plus 3](https://www.mgtek.com/traceview).

!!! important "MGTEK TraceView Plus 3 is not freeware"
    A free 30-day evaluation is available. For longer use, you can [purchase a licence](https://www.mgtek.com/traceview/shop).

2. Double-click `BthPS3.etl` to open it in TraceView Plus, or use **File** → **Open Trace Log...** and select the file:  
   ![Open trace log](../../images/HaKTOUJbIE.png)

3. Initially you will see raw, hard-to-read lines:  
   ![Raw trace view](../../images/TraceView_PZJBtRmyn5.png)

4. TraceView Plus needs symbol files to decode the trace. Go to **Session** → **Add Trace Files...**:  
   ![Add trace files](../../images/TraceView_OtoTHylNPh.png)

5. In the BthPS3 installation folder on your system, select **both** PDB files:  
   ![Select PDB files](../../images/TraceView_GC5KAg7ee8.png)

6. The display should switch to readable text:  
   ![Decoded trace](../../images/TraceView_ju8ERmEEUL.png)

You can then browse the trace; newest events are at the bottom, oldest at the top.

## Interpreting the trace

Once the trace is decoded, look for `TRACE_LEVEL_WARNING` or `TRACE_LEVEL_ERROR` entries. These indicate driver failures and can point to the cause of connection or behaviour issues. Whether the issue can be fixed depends on the specific message and your setup.
