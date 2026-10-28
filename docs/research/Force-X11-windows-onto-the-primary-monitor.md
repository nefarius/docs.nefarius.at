# Force specific X11 windows onto the primary monitor

Some Linux applications open splash screens or authentication dialogs on the
wrong monitor even though the desktop settings and `xrandr` agree on which
display is primary. This can happen when an application ignores the RandR
primary-output flag and centers a window relative to X11 coordinate `(0, 0)`.

This article describes a per-application workaround tested with Cinnamon on
X11. It targets:

- the 300×350 pixel splash screen of the Flatpak version of Vesktop;
- Git Credential Manager dialogs.

Unlike rearranging the complete X11 desktop, these rules do not reverse the
logical direction between monitors.

## Confirm the primary monitor

Check the RandR and Cinnamon view of the display layout:

```bash
xrandr --listmonitors
```

The primary output has an asterisk:

```text
Monitors: 2
 0: +*DisplayPort-1 2560/597x1440/336+1920+0  DisplayPort-1
 1: +DisplayPort-0 1920/531x1080/299+0+0  DisplayPort-0
```

Setting it again is harmless, but does not help applications that ignore the
flag:

```bash
xrandr --output DisplayPort-1 --primary
```

Replace `DisplayPort-1` with the output marked as primary on your machine.

## Identify the affected window

Open the misplaced window, then inspect managed windows:

```bash
wmctrl -lxG
```

For more detail, select the window interactively:

```bash
xprop WM_CLASS _NET_WM_NAME
```

The relevant classes in this example are:

```text
dev.vencord.vesktop
git-credential-manager
```

Vesktop uses the same class for its main window and splash screen. Its splash
can instead be distinguished by its fixed client size of 300×350 pixels.

## Install dependencies

On Debian and Ubuntu based distributions:

```bash
sudo apt install python3-xlib x11-xserver-utils wmctrl xdotool
```

## Add the window rule

Create `~/.local/bin/primary-monitor-window-rules`:

```python
#!/usr/bin/env python3
"""Move selected application windows to the XRandR primary monitor."""

import re
import subprocess
import threading
import time

from Xlib import X, Xatom, display, error


def primary_geometry():
    output = subprocess.check_output(
        ["xrandr", "--listmonitors"], text=True, stderr=subprocess.DEVNULL
    )
    for line in output.splitlines():
        if "*" not in line:
            continue
        match = re.search(r"\s(\d+)/\d+x(\d+)/\d+\+(-?\d+)\+(-?\d+)", line)
        if match:
            width, height, x, y = map(int, match.groups())
            return x, y, width, height
    raise RuntimeError("XRandR primary monitor not found")


connection = display.Display()
root = connection.screen().root
root.change_attributes(
    event_mask=X.SubstructureNotifyMask | X.PropertyChangeMask
)
connection.flush()


def position_if_matched(window_id):
    local_connection = display.Display()
    local_root = local_connection.screen().root
    window = local_connection.create_resource_object("window", window_id)

    # A window may be mapped just before WM_CLASS becomes available.
    for _ in range(10):
        try:
            wm_class = tuple(
                value.lower() for value in (window.get_wm_class() or ())
            )
            geometry = window.get_geometry()

            vesktop_splash = (
                any("vesktop" in value for value in wm_class)
                and geometry.width == 300
                and geometry.height == 350
            )
            credential_dialog = "git-credential-manager" in wm_class

            if vesktop_splash or credential_dialog:
                monitor_x, monitor_y, monitor_w, monitor_h = primary_geometry()
                target_x = monitor_x + (monitor_w - geometry.width) // 2
                target_y = monitor_y + (monitor_h - geometry.height) // 2

                if credential_dialog:
                    # Ask the window manager to move the Avalonia dialog and
                    # the frame that it adds around the client window.
                    subprocess.run(
                        [
                            "xdotool",
                            "windowmove",
                            hex(window_id),
                            str(target_x),
                            str(target_y),
                        ],
                        check=False,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                    )
                else:
                    # Vesktop's frameless Electron splash can be moved
                    # directly through its outermost X11 window.
                    top_level = window
                    while True:
                        parent = top_level.query_tree().parent
                        if parent.id == local_root.id:
                            break
                        top_level = parent
                    top_level.configure(x=target_x, y=target_y)
                    local_connection.flush()

                local_connection.close()
                return
        except (error.XError, error.DisplayConnectionError):
            local_connection.close()
            return
        time.sleep(0.025)

    local_connection.close()


client_list_atom = connection.intern_atom("_NET_CLIENT_LIST")


def inspect_managed_clients():
    clients = root.get_full_property(client_list_atom, Xatom.WINDOW)
    if clients:
        for window_id in clients.value:
            threading.Thread(
                target=position_if_matched,
                args=(int(window_id),),
                daemon=True,
            ).start()


# Also handle a matching dialog that was open before the rule started.
inspect_managed_clients()

while True:
    event = connection.next_event()
    if event.type == X.MapNotify:
        threading.Thread(
            target=position_if_matched,
            args=(event.window.id,),
            daemon=True,
        ).start()
    elif event.type == X.PropertyNotify and event.atom == client_list_atom:
        inspect_managed_clients()
```

Make it executable:

```bash
chmod +x ~/.local/bin/primary-monitor-window-rules
```

The `_NET_CLIENT_LIST` listener is important for Git Credential Manager. Its
toolkit creates an intermediate frame before the actual client window is
registered, so listening only for X11 map events may miss it.

## Start the rule automatically

Create `~/.config/autostart/primary-monitor-window-rules.desktop`:

```ini
[Desktop Entry]
Type=Application
Name=Primary monitor window rules
Comment=Move selected application windows to the primary monitor
Exec=/bin/sh -c "$HOME/.local/bin/primary-monitor-window-rules"
OnlyShowIn=X-Cinnamon;
X-GNOME-Autostart-enabled=true
NoDisplay=true
```

Start it immediately without logging out:

```bash
setsid ~/.local/bin/primary-monitor-window-rules \
  >"${XDG_RUNTIME_DIR:-/tmp}/primary-monitor-window-rules.log" 2>&1 \
  < /dev/null &
```

Fully quit and reopen Vesktop to test its splash screen. Git Credential
Manager will be repositioned whenever its next authentication dialog appears.

## Troubleshooting

Confirm that the rule is running:

```bash
pgrep -af primary-monitor-window-rules
```

Inspect a window's actual X11 position:

```bash
xwininfo -id WINDOW_ID
```

`wmctrl -lxG` is useful for finding the window ID, although some applications
report confusing geometry there. `xwininfo` is more reliable for confirming
the final position.

This solution is specific to X11. Wayland compositors use different APIs and
security rules, so an X11 event listener is not a general Wayland window-rule
mechanism.
