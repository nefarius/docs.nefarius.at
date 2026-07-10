# Download Integrity

The updater can verify the integrity of downloaded release files by comparing a computed hash against a server-provided expected value. This is a lightweight, setup-independent safety net that catches corrupted or accidentally mismatched downloads.

For higher-assurance deployments, combine this with [Authenticode / publisher pinning](Signature-Verification.md).

## Release checksum

Add a `checksum` object to a release entry in your server-side [remote configuration](Remote-Configuration.md):

```json
{
    "releases": [
        {
            "name": "My Product",
            "version": "2.0.0",
            "downloadUrl": "https://example.com/setup.exe",
            "checksum": {
                "checksum": "d41d8cd98f00b204e9800998ecf8427e",
                "checksumAlg": "MD5"
            }
        }
    ]
}
```

### Fields

Field | Type | Mandatory | Description
---|---|---|---
`checksum` | `string` | Yes | The expected hash digest as a lowercase hex string.
`checksumAlg` | `string` | Yes | The hashing algorithm to use. Possible values: `MD5`, `SHA1`, `SHA256`.

The comparison is **case-insensitive**.

!!! warning "Algorithm recommendations"
    Prefer `SHA256` for new configurations. `MD5` and `SHA1` are provided for compatibility but are not collision-resistant; they should not be used in security-sensitive environments.

If the computed hash does not match the expected value, the download is rejected and the update fails with exit code `116`.

## Self-updater checksum

You can also protect the self-updater binary download. Add a `latestChecksum` field to the `instance` block:

```json
{
    "instance": {
        "latestVersion": "1.5.0",
        "latestUrl": "https://example.com/updater.exe",
        "latestChecksum": {
            "checksum": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
            "checksumAlg": "SHA256"
        }
    }
}
```

The self-updater module receives this value and verifies the downloaded binary before swapping it for the running updater.

!!! warning "Algorithm support differs for self-updater"
    The self-updater module only accepts `SHA256` and `SHA1` for `latestChecksum`. Specifying `MD5` will cause self-updater integrity verification to fail. If `latestChecksum` is absent entirely, the self-updater falls back to Authenticode verification only.

## Detection checksum

The `detectionChecksum` field on a release object is separate from the download `checksum`. It is used by the [`FileChecksum` product detection method](Product-Detection.md#filechecksum) to determine whether the locally installed version matches the release, and has no effect on download integrity.

## Strict mode

When the updater is invoked with [`--strict-verification`](Command-Line-Arguments.md#--strict-verification), a release that does not provide a `checksum` object is rejected **after download**, during the integrity check phase. This enforces checksum presence as a policy requirement. The rejection exits with code `116`.

## Related exit codes

Code | Description
---|---
`116` | All post-download integrity/authenticity failures, including checksum mismatch and (when `--strict-verification` is active) a missing `checksum` field.

See [Exit Codes](Exit-Codes.md) for the full list.
