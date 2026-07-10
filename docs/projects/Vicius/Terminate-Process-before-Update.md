# Process Termination on Update

When the user accepts an update, the setup executable needs to overwrite files that belong to the product — files that are typically locked by the product process while it is running. Passing [`--terminate-process-before-update <handle>`](Command-Line-Arguments.md#-terminate-process-before-update-handle) on the command line instructs the updater to forcefully kill that process right before the setup payload runs (i.e. after the user confirms, but before the installer or ZIP extraction begins).

This is the intended pattern when the updater is launched directly **by** the product it governs.

!!! note "Interaction with productBusyDetection"
    When a termination handle is configured the [`productBusyDetection`](Local-Configuration.md#productbusydetection) wait gate is skipped entirely. The updater will not wait for the process to exit on its own — it will forcefully terminate it instead.

## Handle requirements

The value passed to `--terminate-process-before-update` is a Win32 `HANDLE` expressed as a **decimal integer**. The updater validates the handle at startup and silently disables the feature (logging an error) for any of the following:

- **MUST** be a real Win32 `HANDLE` — a **PID is not a handle**. If you only have a PID, obtain a handle first with `OpenProcess()`.
- The handle should have at least `PROCESS_TERMINATE | PROCESS_QUERY_LIMITED_INFORMATION` permissions. `PROCESS_QUERY_LIMITED_INFORMATION` is needed because the updater calls `GetProcessId()` to confirm the handle is valid. The updater does not verify these permissions at startup — an insufficient-permissions handle will fail only when `TerminateProcess` is actually called.
- The handle should be inheritable (`bInheritHandle = TRUE`). This is not checked at startup; without it the handle will be invalid in the child process.
- **MUST NOT** be a pseudo-handle (e.g. the raw return value of `GetCurrentProcess()`). Pseudo-handles are per-process constants whose numeric values are meaningless in any other process. The updater explicitly rejects them.

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
