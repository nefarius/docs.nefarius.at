# Remote Configuration

The updater expects a JSON response from the update server; you can find various implementation details and examples below.

!!! warning "Empty `releases` is not safe"
    Serving an empty `releases` array (`"releases": []`) is **not** a no-op. The updater will successfully parse the response but will then fail product version detection (it needs at least one release to compare against), and exit with code `105` (`NV_E_PRODUCT_DETECTION`). If you want to signal "nothing to do", remove the `emergencyUrl` and use a release whose version matches what you expect users to have installed.

!!! note "Optional vs. required fields"
    Top-level `instance` and `shared` objects are optional and can be omitted. However, each entry in the `releases` array has required fields (`name`, `version`, `summary`, `publishedAt`, `downloadUrl`). Omitting required release fields may cause parsing or version-comparison failures.

## JSON Schema

The current [master branch update response schema](https://github.com/nefarius/vicius/tree/master/abstractions/src/Models) is provided [here](https://vicius.api.nefarius.systems/api/vicius/master/schema.json).

## C# POCO

The response types (classes, enums) are available in the [`abstractions/src/Models`](https://github.com/nefarius/vicius/tree/master/abstractions/src/Models) directory of the repository, published as the **Nefarius.Vicius.Abstractions** NuGet package.

!!! note "Migrating from the old standalone package"
    The standalone [Nefarius.Vicius.Abstractions](https://github.com/nefarius/Nefarius.Vicius.Abstractions) repository has been archived. The package id and namespace are unchanged — simply update your package source/version to pick up the in-repo package.

## C++ models

You can find the C++ types used [here](https://github.com/nefarius/vicius/tree/master/src/models).

## Swagger API documentation

Check out the [Swagger documentation](https://vicius.api.nefarius.systems/swagger/index.html) for the example implementations.

## Hosted examples

An ever growing collection of example configurations [is hosted here](https://vicius.api.nefarius.systems/swagger/index.html#/Examples).

## Related topics

- [Setup Exit Code Handling](Setup-Exit-Codes.md) — configure which setup exit codes are treated as success, attach custom UI messages, and add per-code help buttons.
