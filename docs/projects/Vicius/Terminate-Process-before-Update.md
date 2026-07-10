# Process Termination on Update

When the user accepts an update, the setup executable needs to overwrite files that belong to the product — files that are typically locked by the product process while it is running. Passing [`--terminate-process-before-update <handle>`](Command-Line-Arguments.md#-terminate-process-before-update-handle) on the command line instructs the updater to forcefully kill that process right before the setup payload runs (i.e. after the user confirms, but before the installer or ZIP extraction begins).

This is the intended pattern when the updater is launched directly **by** the product it governs.

!!! note "Interaction with productBusyDetection"
    When a termination handle is configured the [`productBusyDetection`](Local-Configuration.md#productbusydetection) wait gate is skipped entirely. The updater will not wait for the process to exit on its own — it will forcefully terminate it instead.

## Handle requirements

The value passed to `--terminate-process-before-update` is a Win32 `HANDLE` expressed as a **decimal integer**. The updater performs a limited validation at startup and silently disables the feature (logging an error) if validation fails.

**Checked at startup** — the feature is disabled immediately if:

- The value is zero (no handle provided).
- The handle is a pseudo-handle (e.g. the raw return value of `GetCurrentProcess()`). Pseudo-handles are per-process constants whose numeric values are meaningless in any other process.
- `GetProcessId()` on the handle fails — this confirms it is a valid, open kernel handle. A **PID is not a handle**; if you only have a PID, obtain a real handle first with `OpenProcess()`.

**Not checked at startup — may fail at runtime** — the updater does not verify:

- **Permissions**: the handle should have at least `PROCESS_TERMINATE | PROCESS_QUERY_LIMITED_INFORMATION` access rights. `PROCESS_QUERY_LIMITED_INFORMATION` is what makes the startup `GetProcessId()` call succeed; `PROCESS_TERMINATE` is required when `TerminateProcess` is called immediately before the setup runs. An under-privileged handle passes startup validation but will fail at that point.
- **Inheritability**: the handle must be inheritable (`bInheritHandle = TRUE`) so the operating system copies it into the child updater process. This is not validated at startup; a non-inheritable handle will be unusable in the child process even though startup succeeds.

## Step 1 — Create a real, inheritable handle

Use `DuplicateHandle` to turn the `GetCurrentProcess()` pseudo-handle into a real, inheritable handle that refers to the calling process itself:

```c++
HANDLE handle{};
DuplicateHandle(
    GetCurrentProcess(),   // source process  (us)
    GetCurrentProcess(),   // source handle   (pseudo-handle to duplicate)
    GetCurrentProcess(),   // target process  (us — we keep the new handle)
    &handle,
    PROCESS_TERMINATE | PROCESS_QUERY_LIMITED_INFORMATION,
    /* bInheritHandle = */ TRUE,
    /* dwOptions     = */ 0);
```

All three process arguments are `GetCurrentProcess()` because the product and the updater are started from the same process: we are duplicating our own pseudo-handle into a real, inheritable one that the child updater process will receive via handle inheritance.

!!! important "Close the handle if you do not launch the updater"
    `DuplicateHandle` allocates a kernel object. If you create the handle but then decide not to launch the updater, call `CloseHandle(handle)` to avoid a handle leak.

## Step 2 — Build the command line

The inherited handle keeps the same numeric value inside the child process. The updater parses the argument as a **decimal integer**, so stringify the handle value accordingly before appending it to the command line:

```c++
std::wstring cmdLine = LR"("C:\Path\manufacturer_product_Updater.exe")";
cmdLine += L" --silent-update";
cmdLine += L" --terminate-process-before-update ";
cmdLine += std::to_wstring(reinterpret_cast<uintptr_t>(handle));
```

## Step 3 — Launch the updater with handle inheritance enabled

Pass `bInheritHandles = TRUE` to `CreateProcessW` so the operating system copies all inheritable handles — including the one created above — into the child process:

```c++
STARTUPINFOW si{ sizeof(si) };
PROCESS_INFORMATION pi{};
CreateProcessW(
    nullptr,          // lpApplicationName  (use cmdLine instead)
    cmdLine.data(),   // lpCommandLine
    nullptr,          // lpProcessAttributes
    nullptr,          // lpThreadAttributes
    /* bInheritHandles = */ TRUE,
    0,                // dwCreationFlags
    nullptr,          // lpEnvironment
    nullptr,          // lpCurrentDirectory
    &si,
    &pi);
```

## Behavior and failure

!!! warning "Termination is forceful and asynchronous"
    The updater calls `TerminateProcess(handle, 0)` immediately before running the setup. This is an unconditional, hard kill — the target process receives no shutdown messages, open files may not be flushed, and unsaved user data can be lost. Where practical, save state and close cleanly yourself before launching the updater.

    `TerminateProcess` returns before the process has fully exited. The operating system does not guarantee that all file handles held by the process are released by the time the setup starts. If the setup fails due to locked files immediately after termination, a brief wait or retry in the installer itself is the appropriate remedy.

If the `TerminateProcess` call fails for any reason, the updater aborts the update. The failure is reported as exit code `109` (`NV_E_SETUP_FAILED`). Exit code `111` (`NV_E_TERMINATE_PROCESS_BEFORE_UPDATE_FAILED`) is reserved for this condition but is not yet individually emitted.

!!! note "No user confirmation in `--silent-update` mode"
    When the updater is launched with [`--silent-update`](Command-Line-Arguments.md#--silent-update), the process is terminated without any user-facing prompt. Ensure the calling application saves state and notifies the user appropriately before launching the updater in this mode.
