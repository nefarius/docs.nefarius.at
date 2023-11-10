# Remote Configuration

The updater expects a JSON response from the update server; you can find various implementation details and examples below. The updater as a client is quite resilient; every property/field marked as optional/nullable can be omitted entirely in the response. In theory you don't even need to provide any releases in the response, just make it an empty array and you're good to go.

## JSON Schema

The current [master branch update response schema](https://github.com/nefarius/vicius/tree/master/examples/server/Models) is provided [here](https://vicius.api.nefarius.systems/api/vicius/master/schema.json).

## C# POCO

The response types (classes, enums) are available via the [example server implementation](https://github.com/nefarius/vicius/blob/master/examples/server/Models/UpdateResponse.cs).

## C++ models

You can find the C++ types used [here](https://github.com/nefarius/vicius/tree/master/src/models).

## Swagger API documentation

Check out the [Swagger documentation](https://vicius.api.nefarius.systems/swagger/index.html) for the example implementations.
