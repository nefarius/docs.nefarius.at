# Steam, SXS, and rumble

!!! note "Which build this describes"
    Motor rumble over SIXAXIS commands was confirmed on the signed **3.25.0** driver, with current stock Steam, once the steps below were in place. Player-LED decoding, and the ControlApp checkbox that writes the environment variable, ship in the driver and ControlApp build that include the sixaxis command fix. Until that build is installed, set the variable yourself. On **3.25.0**, player LEDs turn off when Steam opens the pad.

SXS mode speaks the same output commands as Sony's `sixaxis.sys`. Steam can use that path, and the motors will move, without replacing Steam's `SDL3.dll`. Two separate switches decide whether anything is sent, and whether the pad acts on it.

## What to do

1. In ControlApp, set the controller to **SXS**. In Steam, leave **PlayStation Configuration Support** enabled.
2. In ControlApp **Settings**, enable **Let Steam talk to SXS controllers natively**. The same switch is the user environment variable `SDL_JOYSTICK_HIDAPI_PS3_SIXAXIS_DRIVER=1`. Fully quit Steam, including the tray icon, and start it again. Steam reads the variable when its process starts.
3. On the device, set **USB output transport** to **Auto** (or **InterruptOut** if you want to force that pipe). Unplug the controller and plug it back in. The running device keeps the transport it opened with.

After that, a program that calls SDL rumble moves the motors. Steam's controller tester still has no Rumble control. That control appears when SDL tells Steam the device can rumble. Stock Steam does not, and the environment variable cannot change that bit inside Steam's DLL.

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

`HIDAPI_DriverPS3SonySixaxis_GetJoystickCapabilities` in current Steam returns no capabilities. Steam's tester draws a Rumble control only when `SDL.joystick.cap.rumble` is set, so the button stays hidden. The same driver already implements rumble (command 2) and the four player LEDs (command 1). Advertising `SDL_JOYSTICK_CAP_RUMBLE` and `SDL_JOYSTICK_CAP_PLAYER_LED` from that function is what makes the tester show the control. A local SDL build with that change reported both properties. Steam's own DLL does not, until Valve ships it.

Leave Steam's `SDL3.dll` where the installer put it. Dropping another DLL into the Steam directory is overwritten by the next Steam update and is not required for the motors.

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
