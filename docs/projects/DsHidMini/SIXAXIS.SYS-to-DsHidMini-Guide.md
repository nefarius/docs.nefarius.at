# Switch from SIXAXIS.SYS to DsHidMini

If the Sony SIXAXIS.SYS driver is present on your system, it may take priority over DsHidMini (on USB) and you need to manually switch drivers like outlined below:

- Plug in your controller
- Open Device Manager by pressing ++win+x++ and select it from the menu:  
![6dCenuSsFr.png](images/6dCenuSsFr.png)  
- Expand `Human Interface Devices` and look for `Wireless controller for PLAYSTATION(R)3`  
![PEWjvrlW65.png](images/PEWjvrlW65.png)  
- Right-click it and select `Update driver`  
![eW3QhFytrY.png](images/eW3QhFytrY.png)
- Follow the wizard:  
![DOVKWWOZpJ.png](images/DOVKWWOZpJ.png)  
![f6RHUblPhy.png](images/f6RHUblPhy.png)  
![27yW8gUtaC.png](images/27yW8gUtaC.png)  
![mmc_Vn3zp43Xg3.png](images/mmc_Vn3zp43Xg3.png)  
- Use [Driver Store Explorer](https://github.com/lostindark/DriverStoreExplorer/releases) to remove the `sixaxis.inf` driver:  
![Ip5SHUMzrE.png](images/Ip5SHUMzrE.png)  

Done 🎉
