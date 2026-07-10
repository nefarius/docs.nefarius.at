# ZIP Archives

ZIP archive updates are intended for 'portable' software, which you extract and run without an installer. If your software has an installer, it is *strongly recommended* that you package your updates as an installer too.

## Usage and Requirements

To use, just put the ZIP address as the `downloadUrl` in your configuration.

The ZIP file:

- must be an actual ZIP file, i.e. not 7-zip, tarball, WinRAR, etc.
- will be extracted verbatim in the same folder as your executable; this means that `foo.zip` should contain `foo.exe` in its' root, not `foo/foo.exe`

By default:

- files that are not in the ZIP will not be modified
- files that already exist will be overwritten by the version in the ZIP

See [Customizing Behavior](#customizing-behavior) for how to change to change this.

## Warnings

If you launch the updater from your executable, you will probably want to use the [`--terminate-process-before-update`](Terminate-Process-before-Update.md) option.

If you include the updater in your zip, you will need to handle updating the updater; there are two ways to do this:

- **Recommended**: set the `runAsTemporaryCopy` option to `true` in the `shared` section of your [local](Local-Configuration.md) or remote configuration (not on the release object).
- set the updater disposition to `CreateIfAbsent` (see below).

If you do not do either, installing your update will fail when attempting to replace the updater, as the file will be in use.

!!! note "Two-phase extraction"
    ZIP archives are first extracted to a temporary directory, and then the files are copied to the destination (the directory containing the watched executable). Zip-slip attacks (paths that escape the destination directory via `..` sequences) are blocked — such entries are skipped with a warning.

## Customizing Behavior

By default:

- files that are not in the ZIP will not be modified
- files that already exist will be overwritten by the version in the ZIP

For both the default and individual paths, you can choose between:

- `CreateOrReplace`: the path is always created/updated
- `CreateIfAbsent`: the path is created if not present, but left alone if it's already there
- `DeleteIfPresent`: the path is deleted if present; there is no error if it is absent

You can change the default with the `zipExtractDefaultFileDisposition` configuration option, or change it for specific paths with the `zipExtractFileDispositionOverrides` key; for example.

## Running the setup as Administrator

!!! warning "`runAsAdmin` has no effect on ZIP file-copy updates"
    For ZIP archives, the update process consists entirely of file copy operations — there is no separate setup executable to launch with elevated privileges. The `runAsAdmin` field is ignored on the ZIP extraction path. Elevation only applies when the downloaded payload is an executable (MSI, EXE, or similar). If your ZIP needs to write to `Program Files`, run the updater itself with elevated privileges via the calling process.

!!! warning "Gating condition for `runAsAdmin`"
    Even for executable payloads, `runAsAdmin` is only honored when `signatureVerificationMode` is `Required` **or** `--strict-verification` is active. Under the default `WhenPresent` mode the field is silently ignored. This prevents a compromised server from abusing the elevation mechanism.

You can change the default with the `zipExtractDefaultFileDisposition` configuration option, or change it for specific paths with the `zipExtractFileDispositionOverrides` key. Note that `DeleteIfPresent` entries are processed in a **second pass** after all files have been extracted — they only affect paths listed in `zipExtractFileDispositionOverrides`, not the default disposition. Example:

```json
{
    "releases": [
        {
            "name": "My Tool",
            "version": "2024.7.18",
            "summary": "Blah blah blah",
            "publishedAt": "2024-07-18T13:15:35Z",
            "downloadUrl": "https://example.com/example.zip",
            "zipExtractDefaultFileDisposition": "CreateOrReplace",
            "zipExtractFileDispositionOverrides": {
                "My-Obsolete-Helper.exe": "DeleteIfPresent",
            }
        }
    ]
}
```
