# Testing Your Controller

## Checking with ControlApp

Now that [DsHidMini](How-to-Install.md) (and optionally [BthPS3](../../BthPS3/How-to-Install.md)) are installed with the default settings, your controller should be able to work with Windows and behave as if it were an Xbox Controller (Xinput Device).  Perform the following steps to test this: 

!!! note "Note"
    A companion application for DsHidMini called **ControlApp** allows for further configuration of your controller. No changes need to be made as the default settings should would just fine and the ControlApp is only being used to verify that everything is working properly.

- Connect your PS3 controller to your computer with a USB cable. (Note: This will also automatically pair your controller to your computer for Bluetooth if you installed BthPS3).
- Download the latest version of **ControlApp** from [here](https://buildbot.nefarius.at/builds/DsHidMini/latest/bin/ControlApp.exe)
- Double click on the newly downloaded **ControlApp.exe**.
- If you see your controller under "Devices" and it's showing "XInput", then it's working properly. (If you installed BthPS3, then you can remove your USB cable and see if it shows connected with XInput too).  
![ControlApp XInput](<images/ControlApp XInput.PNG>)

## Checking with Game Controllers Control Panel
- On the lower left corner of your screen where it says "Type here to search" in your task bar, type "joy.cpl", then press ENTER.  
![Search Bar.png](<images/Search Bar.png>)  
- This will open the "Game Controllers" control panel window. Connect your PS3 controller to your computer with a USB cable or Bluetooth. You should now see your controller in the list as "DS3 Compatible HID Device" and a Status of "OK". Click on the controller to highlight it, then click "Properties".  
![USB Conencted.png](<images/USB Connected.png>)  
- On the next screen, make sure that the "Test" tab is selected. Now move the joysticks and press each button on your controller to see if everything is working. Click "OK" to exit out of the Properties window.  
![Controller Test.png](<images/Controller Test.png>)  

**Congratulations!!** Your PS3 controller has now been set up and verified working on your computer over USB (and optionally Bluetooth). If it doesn't, worry not, [read on here](How-to-Install.md/#troubleshooting)!