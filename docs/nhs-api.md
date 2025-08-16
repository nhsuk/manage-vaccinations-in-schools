# NHS API Integration

Mavis connects to [PDS](pds.md) using the NHS API platform.

## Initial setup

Connections to the NHS API are configured per environment. For each environment
we need to create an API key and a signed JWT. The NHS instructions are below,
incluting instructions for generating the JWKS in our environment.

- [Application-restricted RESTful API - signed JWT authentication](https://digital.nhs.uk/developer/guides-and-documentation/security-and-authorisation/application-restricted-restful-apis-signed-jwt-authentication)
- [Application-restricted RESTful API - API key authentication](https://digital.nhs.uk/developer/guides-and-documentation/security-and-authorisation/application-restricted-restful-apis-api-key-authentication)

## Mavis setup

The API key and private keys are stored in the Rails credentials file and
accessed in the app via the settings in `Settings.nhs_api`. Edit these values in
the credentials using the standard Rails tools, e.g. `rails credentials:edit -e
staging`.

### Creating a new key

Use the standard tools to create an RSA key, NHS recommends it be 4096 bits:

```
[1] pry(main)> pkey = OpenSSL::PKey::RSA.generate(4096)
=> #<OpenSSL::PKey::RSA:0x0000000134fe3578 oid=rsaEncryption>
[2] pry(main)> puts pkey.to_pem
-----BEGIN RSA PRIVATE KEY-----
...
```

The pem goes straight into the credentials file under `nhs_api.jwt_private_key`.

### Adding a new key to the NHS API Management JWKS

We currently host our public keys with NHS API Management. To update the jwks
endpoint we need to generate JWKS with all the relevant keys, and update the
JWKS public key URL on the [Manage vaccinations in schools - INT
page](https://onboarding.prod.api.platform.nhs.uk/MyApplications/ApplicationDetails?appId=32b4731b-1779-460d-a3be-bd45c5bf07fa)
.

To generate the JWKS we need to first import any old keys which we may need to
include for compatibility during the migration period.

You can do this using the pem of the old key:

```
[1] pry(main)> old_pem = <<EOF
-----BEGIN RSA PRIVATE KEY-----
...
EOF
=> "-----BEGIN RSA PRIVATE KEY-----\n..."
[2] pry(main)> old_pkey = OpenSSL::PKey::RSA.new(old_pem)
=> #<OpenSSL::PKey::RSA:0x00000001325a3ab0 oid=rsaEncryption>
[3] pry(main)> old_jwk = JWT::JWK.new(old_pkey, { alg: "RS512" }, kid_generator: ::JWT::JWK::Thumbprint)
=> #<JWT::JWK::RSA:0x0000000131a1a900
 @parameters=
 ...
 @rsa_key=#<OpenSSL::PKey::RSA:0x00000001325a3ab0 oid=rsaEncryption>>
```

Or with the existing JWK JSON, e.g. from the existing JWKS endpoint; you can
find the Public key URL on the Manage vaccinations in schools - INT page linked
above, and curl it to see the existing JWKs.

```
[1] pry(main)> jwks_json = Net::HTTP.get(URI("https://api.service.nhs.uk/mock-jwks/eyJrZXlzIjpbeyJrdHkiOiJSU0EiLCJuIjoibXM4Qk91Zjg5NDRVUnlJR1hkVlZzQXl1dVVTbGZSN1hKRmdtYTVVcWVKZ0RfSTJncnVNcXlZdl80anlDVmtKNFRGRjN1U01HYmJkT1NnUVNTWmV5UEJGQ1ZNS1VQX2hfdmRYYm1jRU9JTC1PSG9aWVo1VF9tWE1Cdnk3dm5WUzlnVURVaXJETWxCSGtfdkN4R1JUOVZnSDQtX2xRN1ZPTktTTDhwV2lfdXhERnFqdzZHOEsyaGNOR05JQzN2bkcxVllMTnpvU1JmeWJtMHdjY0NVR3haVDRkZDZRUDhUTVZ1TFpwbFdSQVBiN25Ld05HbG5ZQlZBT1JjTlRzdFNoSUJGdXNrQzFJNHdpM0RYZ0pEVTNncF9DSWFSOFVfMndZYlBPdGoweXBrZG9VMjQ4RU5DbVg0b1J1LVY1Nks1c3BqZFpfTzlidFpTMDJpXzJnS0FrYW1halg2MUhxenQ1M19YX1VlbmhheDZtMlJyTDZMVjZNdUpmYzhTOG1LRFVpVGRpYVN5V1VrTmVVUTNydXFybUNveVlaalZUOVlUb1NlcUtSUklRUElfa0Z4c1RVTVQ4NnZHcklsNm4zRk10a09NaVB3bGJtTHU0SXRwNHA1RXRaQUlkOHROT0xkb0R3NTRNdEpsWW1qN3JEVkcxcVpmU2xxNko1VVFDQWFTR0lRRG03S0hvOFdCcHBSWUhfeW1ORzRUNjBSS1dZYUZNQmV2cl9odU9zazJwdUhEbVRSdE04b2tLSU55MXQ5MzRsczdiNWQ2QXpzU0o1N0dabGNDOHVvRnFlc1lhdS1LTVJ6NnI2ZnRZUWFSQXpnZXdrOF91eFMwTTRPaXMzRF8waDY1ZnEwVEQ3QzV3cXBUUTNTR29oSzZ4dFJYMG5xcWNfN0FHSWtDcFc3dEUiLCJlIjoiQVFBQiIsImFsZyI6IlJTNTEyIiwia2lkIjoibWF2aXMtaW50LTEifSx7Imt0eSI6IlJTQSIsIm4iOiJzbXZZQUVDRHo0TVVwWm5LWThEYXBxdE9qUm9DcFpxalRTaDBKMzlwNnRWRGtlaUlOM1lYSkdtcGdtd1JJYzB2c1JGQ2hUeHZMX1NYOTRDbVQwN0JqSklYWHJacTY1eWNQdE11NE1zejFjOGRHYVNLRzhHYnFaT1p6SXNIYXI5RWZPeXAxMUQ2NkQzUjk4VTkxRFVodWhxWHRvSEJYVGF0WDJCMnBiM0FMSTJPRWEwcnJvSkh5ODJuaUtBWGp5SzNpMXFveXlfUHh5cXBSXzB0SDBSSnBLMDlZSl9pR1A3RExzWkN6alJpWnRIVzFKX0Qya2JtNWRvcU52aGhiYmNKWnZXWC1iNWk4enVOYzVKNW9CTkZEaHJNNGdvWjFNTWJHSktOVm92eC1wZUFRdi1NMjgwZzJtVnd3S1VXa21zWklaU1RuWjAwSjB0TllXUzdrc1VRajNDSUpqQTMySDdUaUN6SnFBR3prZXhKMjE0V01DN0lYSUZ0bHRLTGMydElTVHhpZzZKVHJsMjN3Tk42ZGY0RnhsSTZ5LUF1dFl2eUE5ZFJEcXRWbGRMeDNIdl9adFNuQ0Z3TlUxNE1DVGVnVTdDRkQ4d0c0Y2doM1k3LWFsdERqUWZSTEhjNGhnNDAxYUhBTno5b2RPSGZvZl85TXBwcnpvc0RvV0g3MnRheXZpZVg3Sm5CZlp6NmpoVVpiQ2xYMXo0a3Buek9UaEtFTUZycGw5R04xU1dndHRNMk9ia3hDeDFoLWhnQ21mWjF1cGpZZFpuaFVYdEd3aFgxYjNob0VibVJ1czdPQURJYmVKS2lBc3lFdjRLWGJSVThqck92TzFNVWZtTkhRNGlPVUdqOFROZ21KVklqZ1lVcDJKclRXcHk5Y0lnYlRmUVRyeWJ4RmZ2U3d0cyIsImUiOiJBUUFCIiwiYWxnIjoiUlM1MTIiLCJraWQiOiJPUHJYZVBHZUZLTDJfRFpvaXE3THg5amNDUWExUEdHaERtV045U2dQNnM4In1dfQ"))
=> "{\"keys\":[{\"kty\":\"RSA\",\"n\":\"smvYAECDz4MUpZnKY8DapqtOjRoCpZqjTSh0J39p6tVDkeiIN3YXJGmpgmwRIc0vsRFChTxvL_SX94CmT07BjJIXXrZq65ycPtMu4Msz1c8dGaSKG8GbqZOZzIsHar9EfOyp11D66D3R98U91DUhuhqXtoHBXTatX2B2pb3ALI2OEa0rroJHy82niKAXjyK3i1qoyy_PxyqpR_0tH0RJpK09YJ_iGP7DLsZCzjRiZtHW1J_D2kbm5doqNvhhbbcJZvWX-b5i8zuNc5J5oBNFDhrM4goZ1MMbGJKNVovx-peAQv-M280g2mVwwKUWkmsZIZSTnZ00J0tNYWS7ksUQj3CIJjA32H7TiCzJqAGzkexJ214WMC7IXIFtltKLc2tISTxig6JTrl23wNN6df4FxlI6y-AutYvyA9dRDqtVldLx3Hv_ZtSnCFwNU14MCTegU7CFD8wG4cgh3Y7-altDjQfRLHc4hg401aHANz9odOHfof_9MpprzosDoWH72tayvieX7JnBfZz6jhUZbClX1z4kpnzOThKEMFrpl9GN1SWgttM2ObkxCx1h-hgCmfZ1upjYdZnhUXtGwhX1b3hoEbmRus7OADIbeJKiAsyEv4KXbRU8jrOvO1MUfmNHQ4iOUGj8TNgmJVIjgYUp2JrTWpy9cIgbTfQTrybxFfvSwts\",\"e\":\"AQAB\",\"alg\":\"RS512\",\"kid\":\"OPrXePGeFKL2_DZoiq7Lx9jcCQa1PGGhDmWN9SgP6s8\"}]}"
[2] pry(main)> jwks_payload = JSON.parse(jwks_json)
=> {"keys"=>
  [{"kty"=>"RSA",
    "n"=>
     "smvYAECDz4MUpZnKY8DapqtOjRoCpZqjTSh0J39p6tVDkeiIN3YXJGmpgmwRIc0vsRFChTxvL_SX94CmT07BjJIXXrZq65ycPtMu4Msz1c8dGaSKG8GbqZOZzIsHar9EfOyp11D66D3R98U91DUhuhqXtoHBXTatX2B2pb3ALI2OEa0rroJHy82niKAXjyK3i1qoyy_PxyqpR_0tH0RJpK09YJ_iGP7DLsZCzjRiZtHW1J_D2kbm5doqNvhhbbcJZvWX-b5i8zuNc5J5oBNFDhrM4goZ1MMbGJKNVovx-peAQv-M280g2mVwwKUWkmsZIZSTnZ00J0tNYWS7ksUQj3CIJjA32H7TiCzJqAGzkexJ214WMC7IXIFtltKLc2tISTxig6JTrl23wNN6df4FxlI6y-AutYvyA9dRDqtVldLx3Hv_ZtSnCFwNU14MCTegU7CFD8wG4cgh3Y7-altDjQfRLHc4hg401aHANz9odOHfof_9MpprzosDoWH72tayvieX7JnBfZz6jhUZbClX1z4kpnzOThKEMFrpl9GN1SWgttM2ObkxCx1h-hgCmfZ1upjYdZnhUXtGwhX1b3hoEbmRus7OADIbeJKiAsyEv4KXbRU8jrOvO1MUfmNHQ4iOUGj8TNgmJVIjgYUp2JrTWpy9cIgbTfQTrybxFfvSwts",
    "e"=>"AQAB",
    "alg"=>"RS512",
    "kid"=>"OPrXePGeFKL2_DZoiq7Lx9jcCQa1PGGhDmWN9SgP6s8"}]}
[3] pry(main)> jwks_payload["keys"].first
=> {"kty"=>"RSA",
 "n"=>
  "smvYAECDz4MUpZnKY8DapqtOjRoCpZqjTSh0J39p6tVDkeiIN3YXJGmpgmwRIc0vsRFChTxvL_SX94CmT07BjJIXXrZq65ycPtMu4Msz1c8dGaSKG8GbqZOZzIsHar9EfOyp11D66D3R98U91DUhuhqXtoHBXTatX2B2pb3ALI2OEa0rroJHy82niKAXjyK3i1qoyy_PxyqpR_0tH0RJpK09YJ_iGP7DLsZCzjRiZtHW1J_D2kbm5doqNvhhbbcJZvWX-b5i8zuNc5J5oBNFDhrM4goZ1MMbGJKNVovx-peAQv-M280g2mVwwKUWkmsZIZSTnZ00J0tNYWS7ksUQj3CIJjA32H7TiCzJqAGzkexJ214WMC7IXIFtltKLc2tISTxig6JTrl23wNN6df4FxlI6y-AutYvyA9dRDqtVldLx3Hv_ZtSnCFwNU14MCTegU7CFD8wG4cgh3Y7-altDjQfRLHc4hg401aHANz9odOHfof_9MpprzosDoWH72tayvieX7JnBfZz6jhUZbClX1z4kpnzOThKEMFrpl9GN1SWgttM2ObkxCx1h-hgCmfZ1upjYdZnhUXtGwhX1b3hoEbmRus7OADIbeJKiAsyEv4KXbRU8jrOvO1MUfmNHQ4iOUGj8TNgmJVIjgYUp2JrTWpy9cIgbTfQTrybxFfvSwts",
 "e"=>"AQAB",
 "alg"=>"RS512",
 "kid"=>"OPrXePGeFKL2_DZoiq7Lx9jcCQa1PGGhDmWN9SgP6s8"}
[4] pry(main)> old_jwk = JWT::JWK.new(jwks_payload["keys"].first)
=> #<JWT::JWK::RSA:0x0000000137f16b88
```

Getting a JWK of tne new key is similar to the pem step above, but once you've
placed those in credentials you can retrieve it directly from there:

```
[1] pry(main)> new_pkey = OpenSSL::PKey::RSA.new(Rails.application.credentials.nhs_api.jwt_private_key)
=> #<OpenSSL::PKey::RSA:0x00000001325a3ab0 oid=rsaEncryption>
[2] pry(main)> new_jwk = JWT::JWK.new(new_pkey, { alg: "RS512" }, kid_generator: ::JWT::JWK::Thumbprint)
=> #<JWT::JWK::RSA:0x0000000131a1a900
 @parameters=
 ...
 @rsa_key=#<OpenSSL::PKey::RSA:0x00000001325a3ab0 oid=rsaEncryption>>

```

With all these JWKs, you can generate a JWKS and export the JSON version of the
JWKS and update the the Public key URL section of the Manage vaccinations in
schools - INT page above.

```
[1] pry(main)> jwks = JWT::JWK::Set.new(old_jwk)
=> #<JWT::JWK::Set:0x0000000137f78180
 ...
[2] pry(main)> jwks.add(new_jwk)
=> #<JWT::JWK::Set:0x0000000137f78180
[3] pry(main)> jwks.export.to_json
=> "{\"keys\":...
```

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

### Key Rotation

Keys should be rotated regularly. When a new key is introduced it's JWK will
automatically be added to the JWKS generated for `/oidc/jwks`, but the old
public key can also be added to `JWKSController::EXTRA_JWK` to ensure a smooth
roll-over.

## Command line tools

NHS API actions can be triggered for testing.

To get an access token to test with:

```shell
$ bin/mavis nhs-api access-token
```
