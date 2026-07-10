# Signature & Manifest Verification

The updater supports multiple, layered security checks to ensure the integrity and authenticity of everything it downloads and processes. All of these layers are optional by default; you can harden them progressively depending on your deployment requirements.

## Overview

The verification pipeline runs in this order after a file is downloaded:

```
1. Checksum verification   (release.checksum)
2. Authenticode chain      (WinVerifyTrust)
3. Publisher pin           (cert field matching)
```

For the update *manifest* fetched from your server, a fourth, build-time layer is available:

```
4. Manifest signature      (Ed25519 / minisign, requires NV_MANIFEST_PUBLIC_KEY at build time)
5. Downgrade protection    (manifestVersion field)
```

---

## Setup Authenticode Verification

These settings live in the `shared` section of the [remote configuration](Remote-Configuration.md) or in the [local configuration](Local-Configuration.md) file. They can also be overridden at the individual release level.

### `signatureVerificationMode`

Controls whether the Authenticode signature of the downloaded setup binary is checked.

Value | Description
---|---
`Disabled` | No Authenticode check is performed.
`WhenPresent` | Check only if the file is signed; unsigned setups are accepted. **(Default)**
`Required` | A valid Authenticode chain is mandatory; unsigned setups are rejected.

!!! example "Example — require every release to be signed"
    ```json
    {
        "shared": {
            "signatureVerificationMode": "Required"
        }
    }
    ```

### `signaturePolicy`

When the Authenticode chain is valid, this policy controls whether the signing certificate identity must also match a configured pin.

Value | Description
---|---
`Relaxed` | A valid, trusted Authenticode chain is sufficient. No identity pinning. **(Default)**
`Strict` | The certificate identity must also match the configured publisher pin. Fails with an error if no pin can be resolved.

!!! warning "Strict policy requires a resolvable pin"
    If you set `Strict` but neither `signatureConfig` nor a per-release `signature` can be resolved (and the updater binary itself is unsigned when using `FromUpdaterBinary`), the update will always be rejected.

### `signatureStrategy`

When `signaturePolicy` is `Strict`, this setting controls where the expected certificate identity comes from.

Value | Description
---|---
`FromUpdaterBinary` | The updater's own signing certificate (subject name) is used as the expected publisher. **(Default)** This is renewal-safe because only the subject name is compared.
`FromConfiguration` | The pin is read from `signatureConfig` (global) or per-release `signature` object.

### `signatureConfig`

An object providing explicit certificate pin fields for the `FromConfiguration` strategy. All fields are optional; only the fields you provide are compared.

!!! important "Cert field stability"
    Not all certificate fields are equally stable across certificate renewals:
    
    - **Stable** (safe to pin long-term): `subjectName` — tied to the legal entity name.
    - **Semi-stable** (use with caution): `issuerName` — may change when you switch CA or the CA rotates its intermediates.
    - **Volatile** (change on every renewal): `serialNumber`, `thumbprintSha1`, `thumbprintSha256` — only safe when these values travel inside a *signed manifest* (`FromConfiguration`), so they can be updated server-side without redeploying the updater.

Field | Type | Description
---|---|---
`subjectName` | `string` | The certificate subject / organization name.
`issuerName` | `string` | The CA / issuer display name.
`serialNumber` | `string` | The certificate serial number (hex).
`thumbprintSha1` | `string` | The SHA-1 thumbprint (hex).
`thumbprintSha256` | `string` | The SHA-256 thumbprint (hex).

!!! example "Global pin from the remote configuration (recommended pattern)"
    ```json
    {
        "shared": {
            "signatureVerificationMode": "Required",
            "signaturePolicy": "Strict",
            "signatureStrategy": "FromConfiguration",
            "signatureConfig": {
                "subjectName": "Nefarius Software Solutions e.U."
            }
        }
    }
    ```

### Per-release overrides

Individual releases can override the global policy by including any of the following fields directly in the release object:

Field | Description
---|---
`signaturePolicy` | Override the global `signaturePolicy` for this release.
`signatureStrategy` | Override the global `signatureStrategy` for this release.
`signature` | An explicit `SignatureConfig` pin for this release. Presence implies `FromConfiguration` for this release regardless of the global `signatureStrategy`.

!!! example "Per-release cert pin (volatile fields safe here because the manifest is signed)"
    ```json
    {
        "releases": [
            {
                "name": "My Product",
                "version": "2.0.0",
                "downloadUrl": "https://example.com/setup.exe",
                "signature": {
                    "subjectName": "Nefarius Software Solutions e.U.",
                    "thumbprintSha256": "aabbcc..."
                }
            }
        ]
    }
    ```

---

## Manifest Signature (Ed25519 / minisign)

This is a **build-time** feature that, when enabled, makes the updater verify the signature of the JSON update manifest *before* trusting any of its content. It is transparent to server operators — you only need to sign your manifest file with `minisign` and serve the sidecar alongside it.

### Enabling

In `CustomizeMe.h`, set `NV_MANIFEST_PUBLIC_KEY` to the base64-encoded public key string from your minisign keypair (the second line of the generated `.pub` file):

```cpp
#define NV_MANIFEST_PUBLIC_KEY "RWS..."
```

When this is defined:

- Verification becomes **mandatory**. If the `.minisig` sidecar cannot be fetched or the signature is invalid, the manifest is rejected and the update check fails.
- The check runs *before* `json::parse`, so a tampered body is never trusted.

!!! warning "Backward compatibility"
    If `NV_MANIFEST_PUBLIC_KEY` is **not** defined in the build, manifest verification is skipped entirely and unsigned deployments continue to work unchanged.

### Key generation

```bash
minisign -G
# Creates ~/.minisign/minisign.key (private) and ~/.minisign/minisign.pub (public)
```

Set `NV_MANIFEST_PUBLIC_KEY` to the second line of `minisign.pub`.

### Signing your manifest

```bash
minisign -S -s ~/.minisign/minisign.key -m updates.json
# Produces updates.json.minisig alongside updates.json
```

Serve both files from the same URL root. The updater derives the sidecar URL automatically by appending `.minisig` to the manifest URL.

### Signing new manifests after a cert renewal

Sign your updated manifest with the **same Ed25519 key**. No redeployment of the updater binary is required.

---

## Downgrade / Rollback Protection

When manifest signing is enabled (`NV_MANIFEST_PUBLIC_KEY` defined), the updater also enforces a monotonically increasing `manifestVersion` field.

Add an unsigned integer as a **root-level** field of your manifest JSON:

```json
{
    "manifestVersion": 42,
    "instance": { ... },
    "releases": [ ... ]
}
```

!!! warning "`manifestVersion` is a root-level field"
    The field must be at the top level of the JSON object, not nested inside `instance`. Nesting it under `instance` will cause it to be ignored.

If the server delivers a manifest whose `manifestVersion` is lower than the last successfully processed version on that client, the update check is rejected. The last seen version is persisted in the registry at `HKCU\Software\<manufacturer>\<product>\Vicius\ManifestVersion`. A registry failure (e.g. write permission error) is non-fatal — the updater logs a warning and continues.

!!! note "Current runtime behavior"
    A manifest rollback detection failure causes `RequestUpdateInfo()` to fail, which the process reports as exit code `104` (`NV_E_SERVER_RESPONSE`). Exit code `119` (`NV_E_MANIFEST_DOWNGRADE`) is reserved for this condition but is not yet individually emitted.

!!! note "Only active when `NV_MANIFEST_PUBLIC_KEY` is defined"
    The downgrade check is only executed when manifest signing is enabled. Without a trusted signature, the manifest version field cannot be trusted.

---

## `--strict-verification`

Passing `--strict-verification` on the command line activates a client-side hardened mode with three effects:

1. **Checksum required** — if the selected release has no `checksum` field, the update is rejected *after download* during the integrity check phase (exit code `116`). The rejection happens post-download, not before.
2. **Server cannot downgrade security** — the server-provided `signatureVerificationMode`, `signaturePolicy`, `signatureStrategy`, and `signatureConfig` fields in `shared` are ignored. Only the settings already baked into the local configuration or forced by the build take effect.
3. **Minimum security floor** — if the merged `signatureVerificationMode` is `WhenPresent` or `Disabled`, it is silently upgraded to `Required`; if `signaturePolicy` is `Relaxed`, it is upgraded to `Strict`.

See [Command Line Arguments](Command-Line-Arguments.md#--strict-verification) for the full argument reference.

---

## Notes on ZIP / non-PE payloads

ZIP archives and other non-executable payloads cannot carry an Authenticode signature. When the updater attempts to verify such a file, the Windows trust infrastructure returns `TRUST_E_SUBJECT_FORM_UNKNOWN`, which the updater treats as "unsigned". Under the default `WhenPresent` mode this is accepted; under `Required` mode or `--strict-verification` it causes the update to be rejected with exit code `116`. If you distribute ZIP archives, keep `signatureVerificationMode` at `WhenPresent` or `Disabled` (and rely on checksums instead), or sign a wrapper executable.

## Related exit codes

Code | Description
---|---
`104` | Manifest processing failure — covers manifest Ed25519 verification failure (code `118`) and manifest version rollback (code `119`), which currently surface as this code.
`116` | All post-download integrity/authenticity failures — covers checksum mismatch (code `115`), invalid or untrusted Authenticode chain, publisher pin mismatch (code `117`), and a missing `checksum` field when `--strict-verification` is active.

!!! note "Granular codes 115, 117, 118, 119 are reserved"
    These codes are defined in the source but are not yet individually emitted. All post-download failures report `116`; all manifest failures report `104`. See the [full exit code reference](Exit-Codes.md#reserved--not-yet-individually-emitted) for details.

See [Exit Codes](Exit-Codes.md) for the full list.
