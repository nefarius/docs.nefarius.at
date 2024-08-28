# Process Termination on Update

If the user chooses to install an update, the updater will terminate the specified process if `--terminate-process-before-update <handle>` is passed on the command line; this is intended for when the updater is launched by the product that is being updated.

This handle:
- **MUST** be a Win32 `HANDLE`
- **MUST** have `PROCESS_TERMINATE | PROCESS_QUERY_LIMITED_INFORMATION` permissions
- **MUST** be inheritable, and owned by the updaters' parent process
- **MUST NOT** be a pseudo-handle, e.g. you can not directly use the return value of `GetCurrentProcess()`

For example, you can create the handle with:

```c++
HANDLE handle {};
DuplicateHandle(
    GetCurrentProcess(),
    GetCurrentProcess(),
    GetCurrentProcess(),
    &handle,
    PROCESS_TERMINATE | PROCESS_QUERY_LIMITED_INFORMATION,
    /* inheritable = */ true,
    /* flags = */ 0);
```

You must also specify that handles are inherited when calling `CreateProcess()` to launch the updater.