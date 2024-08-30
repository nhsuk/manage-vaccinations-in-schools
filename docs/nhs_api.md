# NHS API Integration

Mavis connects to [PDS](pds.md) using the NHS API platform.

## Initial setup

Connections to the NHS API are configured per environment. For each environment
we need to create an API key and a signed JWT. Instructions for each:

- [Application-restricted RESTful API - signed JWT authentication](https://digital.nhs.uk/developer/guides-and-documentation/security-and-authorisation/application-restricted-restful-apis-signed-jwt-authentication)
- [Application-restricted RESTful API - API key authentication](https://digital.nhs.uk/developer/guides-and-documentation/security-and-authorisation/application-restricted-restful-apis-api-key-authentication)

## Mavis setup

The API key and the JWT private key are accessed through Settings in the
`nhs_api` section. See the relevant settings YAML files for examples. For
deployed environments these need to be set in the app secrets. `copilot` is
configured to pull these values from there, and you can add values with to it
with `copilot secret init`.

### Setting up local dev to use the INT environment

By default Mavis is configured to connect with the sandbox environment in
`development` and `test` Rails environments. To develop with and test against
the INT environment you'll need to add this to your `config/settings.local.yml` file:

```
nhs_api:
  base_url: "https://int.api.service.nhs.uk"
  apikey: "APIKEY" # the api key for the INT env
  jwt_private_key: | # the JWT private key for the INT env
    -----BEGIN PRIVATE KEY-----
    ...
    -----END PRIVATE KEY-----
```

You should be able to find necessary keys in the app secrets.

## Rake tasks

NHS API actions can be triggered through Rake tasks for testing.

```
rails nhs:access_token    # Get an access token to test with
```
