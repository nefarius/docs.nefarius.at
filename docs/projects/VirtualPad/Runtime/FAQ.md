# Frequently Asked Questions

An ever growing collection of frequently asked questions and their respective answers 🙃

## Where to find error details if the installation failed?

Open the `Event Viewer` application. You can find it by e.g. a start menu search like seen here:

![AnyDesk_3R6KNfaIMx.png](../images/AnyDesk_3R6KNfaIMx.png)

Next, expand the node `Windows Logs` and select the `Application` log.

By default, there is way too much information displayed we do not need, so select `Filter Current Log...` on the right-side panel:

![gVxmsOd44y.png](../images/gVxmsOd44y.png)

On the upcoming dialog, expand the `Event sources` box and check every element prefixed with `Nefarius`:

![mmc_Tz8BRNWnCV.png](../images/mmc_Tz8BRNWnCV.png)

Click the `Critical` and `Error` event levels so we get less noise:

![hdMNaO215y.png](../images/hdMNaO215y.png)

Now the list should have shrunk down significantly. Now on the right-side panel select `Save Filtered Log File As...`:

![IdA7f9gz1p.png](../images/IdA7f9gz1p.png)

Select a location where to store the export file to and when asked about the Display Information, make sure to select `English` languages (may be one or two entries only):

![gYnGavzf90.png](../images/gYnGavzf90.png)

You can now share the generated `.evtx` file and `LocaleMetaData` directory with support personnel. It's best to compress them using e.g. 7zip or WinRAR or similar to have one single file to share.

Good luck!
