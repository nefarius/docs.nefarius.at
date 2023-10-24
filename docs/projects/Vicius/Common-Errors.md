# Common Errors

The updater will try its best to not disturb the user unless absolutely necessary. Some errors can not be recovered from, though, so check out what you can do below.

## Requests blocked by firewall

Typically on vanilla Windows the Windows Firewall does not block any **outgoing** request so everything should be fine.

However if 3rd party software firewalls (like [simplewall](https://www.henrypp.org/product/simplewall)) are used, users might get a notification like...

![simplewall_XugngWvkH7.png](images/simplewall_XugngWvkH7.png)

...and would need to accept the outgoing connection for the core functionality to work.

If the connection is blocked, an error message similar to...

![nefarius_HidHide_Updater_5r14wNiMDp.png](images/nefarius_HidHide_Updater_5r14wNiMDp.png)

...might appear and needs to be rectified by the user (or the setup package the updater is bundled with).
