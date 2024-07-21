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

## Invalid detection method

![Updater_O32X4ghzfb.png](images/Updater_O32X4ghzfb.png)

This error can pop up when the updater is run without any silent switches and neither the server nor the local configuration file provided any details on how to detect the version of the product it watches over.

## Updater process module hash mismatch

![contoso_EmergencyUrl_Updater_4i9Krd4eBy.png](images/contoso_EmergencyUrl_Updater_4i9Krd4eBy.png)

This error indicates that the updater was called with the [`--temporary`](Command-Line-Arguments.md#-temporary) flag outside of supported operation. I told you to not fiddle with it and that's what you get for being nosey 😆
