# Collecting Runtime Trace Logs

## Remote Collection, Driver and Runtime

Open a PowerShell/Windows Terminal **as Administrator*. If unsure how to do: consult a search engine of your choice 😉

Now copy and paste the following lines verbatim into the shell and press Enter:

```PowerShell
New-EtwTraceSession -Name VPadRuntime -LogFileMode 0x8100 -FlushTimer 1 -LocalFilePath "C:\VPadRuntime.etl" 2>&1 | Out-Null
Add-EtwTraceProvider -SessionName VPadRuntime -Guid '{021B2C3C-9DD6-4C0A-A53A-6183F1BE11A0}' -MatchAnyKeyword 0x0FFFFFFFFFFFFFFF -Level 0xFF -Property 0x40 2>&1 | Out-Null
Add-EtwTraceProvider -SessionName VPadRuntime -Guid '{afebad70-d5db-4a74-bda2-764d2a875aaf}' -MatchAnyKeyword 0x0FFFFFFFFFFFFFFF -Level 0xFF -Property 0x40 2>&1 | Out-Null
```

**You can now perform the action which causes the problem!**

When done, in the same shell window, copy and paste the following with an additional Enter key press:

```PowerShell
Remove-EtwTraceSession -Name VPadRuntime 2>&1 | Out-Null
```

Now **compress** (7zip, WinRAR, ...) the generated file `C:\VPadRuntime.etl` and send it to support personnel!

## Live View, Runtime only

Download and install [TraceView Plus](https://www.mgtek.com/traceview) and launch it as Administrator.

Open the `Session` menu and select `Trace Provider...`:

![2RSqIYzTFm.png](images/2RSqIYzTFm.png)

In the upcoming dialog, choose `Add Provider`:

![HIN2XXC51N.png](images/HIN2XXC51N.png)

In the presented list, select the `Nefarius VirtualPad Runtime` entry and click OK:

![zLPjj9mp7X.png](images/zLPjj9mp7X.png)

Clock OK again:

![vJDIIE5kPK.png](images/vJDIIE5kPK.png)

Now click the little green "Plus" icon on top:

![5JfKFF33GE.png](images/5JfKFF33GE.png)

You should now see `Starting trace session.` in the lower panel:

![OUbk0CY1Vf.png](images/OUbk0CY1Vf.png)

Now the trace is running and collecting events from the runtime, example below:

![TraceView_8noVKlTS1g.png](images/TraceView_8noVKlTS1g.png)
