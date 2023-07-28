# Nefarius VirtualPad Runtime .NET Exceptions

!!! attention "This topic is targeted at developers"
    The contents of this article are for a developer audience, if you need support with the runtime [please contact us via the appropriate channels](../../../Community-Support.md).

## VirtualPadApiDriverNotFoundException

No compatible driver was found on the system. Please make sure that driver and runtime are present on the machine by executing the latest setup.

## VirtualPadApiDriverAccessFailedException

A driver was found but couldn't be accessed. This can hint at multiple issues:

- The process using the runtime API is not trusted by it.
- There's been some unforeseen internal error that needs additional debugging to figure out the root cause.

## VirtualPadApiDriverVersionMismatchException

The invoked API is not available with the driver version currently present on the system. Please update to a newer version of the driver (and runtime setup) and retry.

## VirtualPadApiDriverLicenseExpiredException

Indicates that the license present on the machine has expired. Please make sure that the machine experiencing this error has internet access and has the service `Nefarius VirtualPad Driver Service` running. You can consult the `Application` logs in the Windows Event Viewer and check for errors from the source `Nefarius VirtualPad Driver Service`. Restart the service and ensure it is not firewall'ed.
