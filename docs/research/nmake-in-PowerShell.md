# Have MSBuild/nmake available in PowerShell

The following guide will modify all new PowerShell instances to run the required preparations to invoke MSBuild/nmake.

Open (or create) the profile file `"$((new-object -COM Shell.Application).Namespace(0x05).Self.Path)\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"` and add [the following content](https://gist.github.com/nefarius/b60a498b0229b5cf0e338b7a39460b80).
