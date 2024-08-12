# Setting up a connection with NHS Hessage Exchange for Social Care and Health (MESH)

To connect with NHS MESH in the integration or production environments, you'll
need a mailbox allocated and a TLS certificate generated for you. These are
different in each environment. To get these you'll need:

- an ODS code for your organisation
- to have begun onboarding with the [NHS Digital onboarding
  service](https://onboarding.prod.api.platform.nhs.uk/Products); your use case
  for MESH should be accepted before you start integrating with it

For development, you can run the [MESH Sandbox](https://github.com/NHSDigital/mesh-sandbox)
locally without either of these, but SSL verification should disabled by setting
`Settings.mesh.disable_ssl_verification?` to true. For new environments the
steps below will need to be followed.

## Getting a MESH Mailbox

Request a MESH mailbox using the link [Apply for a MESH mailbox - NHS England
Digital](https://digital.nhs.uk/services/message-exchange-for-social-care-and-health-mesh/messaging-exchange-for-social-care-and-health-apply-for-a-mailbox),
follow the instructions there. You should receive the mailbox name, id and
password. You'll also need the shared secret for environment, if you don't have
it already you can email itoc.supportdesk@nhs.net to get it.

## TLS Certificate

### Generating the private key and certificate request

Generate a private key in the file `private_key.pem`, enter an appropriate
passphrase when prompted:

```shell
openssl genpkey -algorithm RSA -out private_key.pem -aes256
```

Decide on a common name using the mailbox id received and our ODS code:
`mailboxid.n1g3b.api.mesh-client.nhs.uk`. Some of the NHS docs suggest using
`server001` instead of the `mailboxid` or something similar, but this patterns
fits Mavis better where we'll have one TLS certificate per environment.

Then use the common name when generating the CSR (make sure to add your common
name below):

```shell
openssl req -new -key private_key.pem -out request.csr -subj "/CN=mailboxid.n1g3b.api.mesh-client.nhs.uk"
```

Email the `request.csr` file that's generated to ITOC support with a request to
generate the TLS certificate. Include the application name, mailbox id,
environment and common name from above.

### Configuring the app

Save the root CA and sub CA from [Integration environments - NHS England
Digital](https://digital.nhs.uk/services/path-to-live-environments/integration-environment#rootca-and-subca-certificates)
into the bundle file `config/mesh_ca_bundle.pem` ensuring the root CA comes
first.

Next add the mailbox password, shared key, private key and it's passphrase to
the app secrets. This can be done using `copilot secret init` and entering the
new value for the relevant environment(s).

## Additional resources

- [Message Exchange for Social Care and Health (MESH) API - NHS England Digital](https://digital.nhs.uk/developer/api-catalogue/message-exchange-for-social-care-and-health-api#overview--end-to-end-process-to-integrate-with-mesh-api)
- [Apply for a MESH mailbox - NHS England Digital](https://digital.nhs.uk/services/message-exchange-for-social-care-and-health-mesh/messaging-exchange-for-social-care-and-health-apply-for-a-mailbox) - part of the application form for the MESH mailbox touches on creating a request for a TLS cert
- [Message Exchange for Social Care and Health: certificate guidance - NHS England Digital](https://digital.nhs.uk/services/message-exchange-for-social-care-and-health-mesh/mesh-guidance-hub/certificate-guidance) - more detailed instructions that targets Windows systems, but still useful
