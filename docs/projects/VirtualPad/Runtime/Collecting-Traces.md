# Collecting Runtime Trace Logs

## Preparations

!!! important "Only necessary once"
    If you've performed this step once before on this PC, you can skip it!

Download the file [`nssvpd_debugging.reg`](nssvpd_debugging.reg) to some arbitrary location on your PC and execute it. Confirm the upcoming dialogs and **reboot once** (important)!

## Remote Collection, Driver and Runtime

Open a PowerShell/Windows Terminal **as Administrator**. If unsure how to do: [consult a search engine of your choice](https://googlethatforyou.com?q=how%20to%20open%20powershell%20as%20administrator) 😉

Now copy and paste the following lines verbatim into the shell and press Enter:

```PowerShell
New-EtwTraceSession -Name VPadRuntime -LogFileMode 0x8100 -FlushTimer 1 -LocalFilePath "C:\VPadRuntime.etl" 2>&1 | Out-Null
Add-EtwTraceProvider -SessionName VPadRuntime -Guid '{021B2C3C-9DD6-4C0A-A53A-6183F1BE11A0}' -MatchAnyKeyword 0x0FFFFFFFFFFFFFFF -Level 0xFF -Property 0x40 2>&1 | Out-Null
Add-EtwTraceProvider -SessionName VPadRuntime -Guid '{AFEBAD70-D5DB-4A74-BDA2-764D2A875AAF}' -MatchAnyKeyword 0x0FFFFFFFFFFFFFFF -Level 0xFF -Property 0x40 2>&1 | Out-Null
```

!!! attention "These commands don't return anything!"
    You will not get any output when entering the commands, that is on purpose and fine, not an error.

👉 **You can now perform the action which causes the problem!**

When done, in the same shell window, copy and paste the following with an additional Enter key press:

```PowerShell
Remove-EtwTraceSession -Name VPadRuntime 2>&1 | Out-Null
```

Now [**compress**](https://googlethatforyou.com?q=how%20to%20compress%20files%20on%20Windows) (7zip, WinRAR, ...) the generated file `C:\VPadRuntime.etl` and send it to support personnel!
