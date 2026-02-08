# Amazon's Choice "Pro Controller" Compatibility

!!! danger "This controller cannot be connected to Windows Bluetooth"
    This controller does not follow the Bluetooth specification for channel encryption and therefore cannot be connected to Windows. It has been tested with legacy ScpToolkit and BthPS3; details are below.

## About

This is a third-party controller modelled after the Sony DualShock 3 and sold as PlayStation 3–compatible.

Alternative names:

- Diswoe Wireless Controller

## Product page

[Molyhood Wireless Controller for PS3 (Amazon)](https://www.amazon.de/dp/B07MCGVKHD/ref=cm_sw_em_r_mt_dp_kfYOFbKHBJ5CE?_encoding=UTF8&psc=1)

## Product pictures

![Controller front](../../images/61qdiSaiePL._AC_SX679_.jpg)
![Controller back](../../images/71dnU4cCpnL._AC_SX679_.jpg)
![Controller detail](../../images/20201104_225115.jpg)

## Wireshark

A packet capture shows the Windows Bluetooth stack responding with `Result: Refused - security block (0x0003)` when opening the channel:

![Wireshark capture](../../images/fHOkn7s9Be.png)

## Event Viewer

This connection error is logged in the Windows Event Log under **Windows Logs** → **System**, from the `BTHUSB` source:

`Windows rejected a device connection because the device didn't establish encryption prior to the service level connection.`

![Event Viewer](../../images/AnyDesk_1st9aPmQro.png)
