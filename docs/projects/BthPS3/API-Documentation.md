# API Documentation

!!! important "For developers"
    This section is for **developers** who want to build on BthPS3 and communicate with devices directly for prototyping or experimentation.

Devices connected through BthPS3 can be used without a dedicated driver by opening a handle and talking to the HID Control and Interrupt channels. Enumerate them with [SetupAPI](https://docs.microsoft.com/en-us/windows-hardware/drivers/install/setupapi) using the [device interface GUIDs in the project sources](https://github.com/nefarius/BthPS3/blob/e28e815fe50d91aeb5af692cff29946647d0fa24/common/include/BthPS3.h#L189-L211). Read and write L2CAP channels via [DeviceIoControl](https://docs.microsoft.com/en-us/windows/win32/api/ioapiset/nf-ioapiset-deviceiocontrol) with [these IOCTL commands](https://github.com/nefarius/BthPS3/blob/e28e815fe50d91aeb5af692cff29946647d0fa24/common/include/BthPS3.h#L357-L375).

## Example implementation

For a reference implementation (C#/.NET) that enumerates and interacts with BthPS3 devices, see the [archived Shibari BthPS3 source](https://github.com/nefarius/Shibari/tree/master/Sources/Shibari.Sub.Source.BthPS3).
