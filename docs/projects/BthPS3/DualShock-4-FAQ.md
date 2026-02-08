# DualShock 4 FAQ

## Pairing a DualShock 4 to Windows

Pairing is the same as without BthPS3. Put the controller into PC mode (use the dedicated pairing button combination—search for "DualShock 4 PC pairing" for steps). The controller will then appear in Windows Bluetooth settings.

## Reconnecting an already paired DualShock 4 to Windows

Reconnecting (turning the controller on with the PS button so it connects over Bluetooth) works differently when BthPS3 is installed.

**Without BthPS3:**

- Press the PS button to wake the controller.
- It connects to Windows after a few seconds.

**With BthPS3:**

- **First attempt:** Press the PS button to wake the controller.
  - The light bar blinks white for a few seconds, then the controller turns off. This is expected.
- **Second attempt:** Within **10 seconds**, turn the controller on again (press the PS button).
  - Wait for it to connect. If it does not connect within that 10-second window, repeat from the first attempt.

## Why does reconnecting work this way with BthPS3?

With BthPS3 installed there are two situations:

- **Filter enabled:** PS3 controllers can connect; the DS4 can connect but Windows and tools (DS4Windows, Steam, etc.) will not see it as a controller.
- **Filter disabled:** DS4 controllers work normally; DS3 controllers cannot connect.

With default BthPS3 settings, when you try to reconnect a DS4:

1. The filter is on, so DS3 controllers can connect.
2. You wake the DS4; it tries to reconnect.
3. The DS4 connects, but the filter treats it as unsupported and drops the connection almost immediately (the controller turns off). That is the "first attempt" above.
4. After dropping the DS4, the filter turns itself off. Already connected PS3 controllers stay connected; you just cannot connect new ones for a while.
5. After 10 seconds (by default), the filter turns itself back on.
6. Because the filter is off only for those 10 seconds, you must turn the DS4 on again **within that window** so it can reconnect before the filter comes back. That is the "second attempt."
7. Once the DS4 is connected, it stays connected. When the filter turns back on, the DS4 is not dropped. You can then connect PS3 controllers again as well.
