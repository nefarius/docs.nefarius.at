# Steam, SXS, and rumble

!!! note "Which build this describes"
    Motor rumble over SIXAXIS commands was confirmed on the signed **3.25.0** driver, with current stock Steam's `SDL3.dll`, once the steps below were in place. Player-LED decoding and the ControlApp checkbox that writes the environment variable ship in **3.25.1**. On **3.25.0**, player LEDs turn off when Steam opens the pad.

!!! warning "Use XInput mode for Steam"
    SXS is the mode for [RPCS3](FAQ.md#how-do-i-use-dshidmini-with-rpcs3) and the [SCP XInput Bridge](SCP-XInput-Bridge.md) proxy DLL. It is not the mode for Steam. Steam files every `054C:0268` device under its own PS3 controller type and, in the tested SXS and SDF configurations, never forwarded game rumble to it, whatever SDL reported. **XInput** mode presents an Xbox controller, which Steam treats like any other Xbox pad, with or without Steam Input; rumble then depends on the game supporting Xbox-controller rumble. Setup is in [XInput mode — Setting up Steam](XInput-Mode-Explained.md#setting-up-steam). This page explains why the SXS route is a dead end, for the curious and for anyone who has to use SXS with an SDL3 program outside Steam.

SXS mode speaks the same output commands as Sony's `sixaxis.sys`. SDL3 can use that path, and the motors will move, without replacing Steam's `SDL3.dll`. Two separate switches decide whether anything is sent, and whether the pad acts on it. Steam Input is the one SDL3 consumer that never sends; see [What Steam Input does with a PS3 type](#what-steam-input-does-with-a-ps3-type).

## What to do

For Steam and Steam games: switch the pad to **XInput** in ControlApp and replug. Nothing else on this page is needed.

For SXS with a program that uses SDL3 directly, for example an SDL3 game or tool started outside Steam Input:

1. In ControlApp, set the controller to **SXS**.
2. In ControlApp **Settings**, enable **Let Steam talk to SXS controllers natively**. The same switch is the user environment variable `SDL_JOYSTICK_HIDAPI_PS3_SIXAXIS_DRIVER=1`. Fully quit the program (for Steam, including the tray icon) and start it again; SDL reads the variable when the process starts.
3. On the device, set **USB output transport** to **Auto** (or **InterruptOut** if you want to force that pipe). Unplug the controller and plug it back in. The running device keeps the transport it opened with.

After that, a program that calls SDL rumble moves the motors. Steam's controller tester still has no Rumble control. That control appears when SDL tells Steam the device can rumble. Stock Steam does not, and the environment variable cannot change that bit inside Steam's DLL. Even with the bit set, Steam does not rumble the pad; see below.

## What Steam Input does with a PS3 type

Steam classifies controllers from its own vendor and product id table, not from the transport SDL picked. In both SXS and SDF, `controller.txt` said `Product: PS3 Controller`, `controller_ui.txt` said `Type: 33`, and the config set file was `configset_controller_ps3.vdf`. GPJ and CGP report the same `054C:0268` and so land in the same table entry, but rumble under Steam Input was not measured in those modes. Only XInput mode, with its Xbox vendor and product id, lands in a different type.

With an SDL3 build that advertises rumble, Steam reads `SDL.joystick.cap.rumble -> 1`, records a rumble capability flag for the pad, and shows the Rumble control in the tester. It then sends nothing. Over three Steam sessions and a game with Steam Input forced on, Steam called `SDL_RumbleGamepad` zero times for the DualShock 3:

- in SXS over the SIXAXIS HIDAPI driver,
- in SDF over DirectInput, where the PID descriptor gives SDL a working force-feedback path,
- in both of those again with Steam started as `steam.exe -steamdeck`.

In the same client, same `SDL3.dll` and same game, a DualSense plugged in next to it received 111 `SDL_RumbleGamepad` calls, each one ending in a HID write, and the game rumbled it. Steam's SDL rumble path is intact. The gate sits in steamclient's handling of its PS3 type.

Steam's own settings were not the cause. The per-controller file `preferences_54c-268-….vdf` has `"rumble" "1"`, both config set files are empty, and there is no rumble key for the pad in `localconfig.vdf` or the registry. The same symptom, native rumble working and Steam Input never rumbling a DualShock 3, has been reported against Steam on Linux as [steam-for-linux#7594](https://github.com/ValveSoftware/steam-for-linux/issues/7594). A DsHidMini or SDL change cannot lift it.

Two side effects of that classification are worth knowing:

- Steam applies the SDL mapping database entry for `054C:0268` to every mode. That entry describes the `sixaxis.sys` button order, which is the SXS layout. Under Steam Input, SDF, GPJ and CGP get the wrong buttons. Without Steam Input the game reads the HID device itself and is unaffected.
- The tester's Rumble control is not a test of anything. In the same sessions it also did nothing for the DualSense, and no SDL rumble call was logged for either pad while it was pressed. Use a game.

### How this was measured

SDL3 has a built-in override: when the environment variable `SDL3_DYNAMIC_API` points at another `SDL3.dll`, Steam's own copy forwards every SDL call to that file at startup. A local SDL build with logging in `SDL_RumbleGamepad`, `SDL_RumbleJoystick`, `SDL_SendJoystickEffect`, `SDL_hid_write` and the capability property reads was started this way:

```powershell
$env:SDL3_DYNAMIC_API = 'D:\path\to\SDL3.dll'
$env:SDL_JOYSTICK_HIDAPI_PS3_SIXAXIS_DRIVER = '1'
Start-Process 'C:\Program Files (x86)\Steam\steam.exe'
```

Steam's `SDL3.dll` stays untouched, which matters because Steam restores that file on start. Child processes inherit the variable, so a game shipping its own `SDL3.dll` is redirected too; clear it afterwards. The log showed Steam opening the pad, polling the SIXAXIS feature report for input, writing two player-LED commands at open, reading the four `SDL.joystick.cap.*` properties, and nothing else for the DualShock 3. Driver traces taken earlier with stock Steam, one during a game with Steam Input on and one while the tester was open, had already shown zero output reports arriving from Steam. The SDL log is the reason: nothing is lost between SDL and the driver, Steam never calls.

## Why DirectInput never rumbles

Steam's default for an SXS controller is DirectInput. In `logs\controller.txt` that shows up as an `sdl://` device whose GUID ends in `0000`, for example `0300d8234c0500006802000000000000`.

The SXS HID report has buttons and axes. It has no PID force-feedback collection. DirectInput rumble needs that collection, so Steam reads the pad and writes nothing. A USB capture taken while the tester's Rumble control was pressed showed interrupt IN traffic from the controller and no interrupt OUT, and no `SET_REPORT`. No driver build can rumble a packet Steam never sends.

## What the environment variable changes

`SDL_JOYSTICK_HIDAPI_PS3_SIXAXIS_DRIVER=1` selects SDL's Sony SIXAXIS HIDAPI driver. Steam does not set this hint itself. SDL checks the process environment, so the user variable is enough after a full restart.

`controller.txt` then names the device **PS3 Controller** and logs `Controller using HIDAPI driver, vid=0x054c, pid=0x0268`. The GUID ends in `016800` (HIDAPI's signature byte is `0x68`), for example `03007a2e4c0500006802000000016800`.

That driver sends `sixaxis.sys` output commands. hidapi strips a leading report id of `0` before the write, so the first byte the driver sees is the command:

| Offset | Command 2, rumble | Command 1, player LEDs |
| --- | --- | --- |
| 0 | `02` | `01` |
| 1–3 | padding, left `00` | padding, left `00` |
| 4 | small-motor duration, `FF` while rumbling | LED 4: `00` off, `01` on, `02` flash |
| 5 | small motor, `00` or `01` | LED 3, same modes |
| 6 | large-motor duration, `FF` while rumbling | LED 2, same modes |
| 7 | large-motor force, `00`–`FF` | LED 1, same modes |

A captured rumble pulse on the wire was `00 FF 01 FF FF`, then `00 FF 00 FF 00` about a second later. Commands 3, 9, and 10 carry no motor or LED update. RPCS3 keeps sending its existing full output report; that path stays byte-identical.

`SDL_RumbleJoystick` returns success on stock Steam even while the capability bit below is false. The motors moved on that call.

## Why the tester still hides Rumble

`HIDAPI_DriverPS3SonySixaxis_GetJoystickCapabilities` in current Steam returns no capabilities. Steam's tester draws a Rumble control only when `SDL.joystick.cap.rumble` is set, so the button stays hidden. The same driver already implements rumble (command 2) and the four player LEDs (command 1). Advertising `SDL_JOYSTICK_CAP_RUMBLE` and `SDL_JOYSTICK_CAP_PLAYER_LED` from that function is what makes the tester show the control. A local SDL build with that change reported both properties, and Steam drew the control when run against it through `SDL3_DYNAMIC_API`. Pressing it did nothing, for the reason given above. The capability fix is still the right thing for SDL, since every other SDL3 program gains the two properties, but it is not what stands between a Steam game and this pad.

Leave Steam's `SDL3.dll` where the installer put it. Steam puts its own copy back on start, and the file is not required for the motors.

## Why the pad can ignore a correct rumble packet

SXS output can leave the PC on two USB paths:

- **ControlEndpoint** — class `SET_REPORT` on endpoint 0, `wValue` `0x0201`, 48 byte body, no report id. Setup bytes `21 09 01 02 00 00 30 00`.
- **InterruptOut** — the interrupt OUT pipe. A DualShock 3 exposes this as endpoint `0x02`.

**Auto** uses the interrupt OUT pipe when it exists, and the control endpoint otherwise. The choice is applied when the device is opened. Saving the setting, or editing `%ProgramData%\DsHidMini\DsHidMini.json`, leaves the already-open device on its old path until you replug.

On a DualShock 3 that has the interrupt OUT pipe, the correct command 2 bytes on the control endpoint left the motors still, including while the pad was held. The same `SDL_RumbleJoystick` call moved them after the device was reopened on **Auto**. The control endpoint remains the right choice for pads that have no usable interrupt OUT pipe. If a trace shows a successful rumble write and the motors stay still, check this setting before chasing Steam.

Bluetooth output is a separate channel. This capture was USB.

## Why the LEDs go out

With LED control authority set to **Automatic**, the driver draws its own pattern until an application writes an output report. It then leaves the LEDs to that application until the device is restarted. **Driver** keeps the pattern you selected. **Application** never applies the driver's pattern.

In single-LED battery mode, a pad that reports charged or full lights **LED 4** only. Seeing LED 4 on after a replug is that pattern coming back, not a Steam player light.

Stock **3.25.0** already places command 2's motor bytes correctly. It copies command 1 from byte 3 into the output buffer. Those LED mode bytes land in the motor slots (LED 1's "on" value becomes a large-motor force of 1, which you cannot feel), and the LED flag byte stays 0. Automatic authority then stops restoring the battery pattern, so every LED goes out and stays out until the next replug. A later command 1 can also wipe a rumble that was already playing.

The sixaxis command decoder keeps the two writes apart. Command 2 updates the motors and leaves the LED block alone. Command 1 updates the four player LEDs and leaves the motors alone. With authority **Automatic** or **Application**, player LEDs follow Steam. With authority **Driver**, command 1 does not override the pattern selected in ControlApp. That decoder is not in the signed **3.25.0** driver.

## Related

- [HID device modes — SXS](HID-Device-Modes-Explained.md#sxs)
- [ControlApp overview](ControlApp-Overview.md)
- [Steam lists the same pad twice](XInput-Mode-Explained.md#steam-lists-the-same-pad-twice)
