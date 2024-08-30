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

- **Recommended**: set the `runAsTemporaryCopy` option to `true`
- set the updater disposition to `CreateIfAbsent` (see below)

If you do not do either, installing your update will fail when attempting to replace the updater, as the file will be in use.

## Customizing Behavior

By default:

- files that are not in the ZIP will not be modified
- files that already exist will be overwritten by the version in the ZIP

For both the default and individual paths, you can choose between:

- `CreateOrReplace`: the path is always created/updated
- `CreateIfAbsent`: the path is created if not present, but left alone if it's already there
- `DeleteIfPresent`: the path is deleted if present; there is no error if it is absent

You can change the default with the `zipExtractDefaultFileDisposition` configuration option, or change it for specific paths with the `zipExtractFileDispositionOverrides` key; for example:

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
