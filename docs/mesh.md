# NHS Message Exchange for Social Care and Health (MESH) integration

## Initial setup

To connect with NHS MESH in the integration or production environments, you'll
need a mailbox allocated and a TLS certificate generated for you. These are
different in each environment. To get these you'll need:

- an ODS code for your organisation
- to have begun onboarding with the [NHS Digital onboarding
  service](https://onboarding.prod.api.platform.nhs.uk/Products); your use case
  for MESH should be accepted before you start integrating with it

For development, you can run the [MESH Sandbox](https://github.com/NHSDigital/mesh-sandbox)
locally without either of these, but SSL verification should disabled by setting
`Settings.mesh.disable_ssl_verification` to true. For new environments the
steps below will need to be followed.

### Getting a MESH Mailbox

Request a MESH mailbox using the link [Apply for a MESH mailbox - NHS England
Digital](https://digital.nhs.uk/services/message-exchange-for-social-care-and-health-mesh/messaging-exchange-for-social-care-and-health-apply-for-a-mailbox),
follow the instructions there. You should receive the mailbox name, id and
password. You'll also need the shared secret for environment, if you don't have
it already you can email itoc.supportdesk@nhs.net to get it.

The password and shared secret need to be added to the app secrets, and the
mailbox identifier to the environment's settings YAML. See the section on
configuring the app for more detail.

### TLS Certificate

#### Generating the private key and certificate request

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

### Adding the certificates to the app

Save the root CA and sub CA from [Integration environments - NHS England
Digital](https://digital.nhs.uk/services/path-to-live-environments/integration-environment#rootca-and-subca-certificates)
into the bundle file `config/mesh_ca_bundle.pem` ensuring the root CA comes
first.

The certificates, the private key and it's passphrase will need to be added to
the app secrets. The app is configured to pull these out. See the section on
configuring Mavis for more detail.

## Configuring Mavis

The connection to MESH is configured using Settings (see the YAML files in
`config/settings/*`).

- **base_url**: Environment-specific URL for MESH
- **mailbox**: _Secret_ - Mavis' MESH mailbox, requested from ITOC support
- **password**: _Secret_ - Password for Mavis' mailbox, comes with the mailbox from ITOC support
- **dps_mailbox**: Destination mailbox for DPS
- **shared_key**: _Secret_ - Shared key, also supplied by ITOC support
- **private_key**: _Secret_ - Mavis' key used to generate the certificate
- **private_key_passphrase**: _Secret_ - Passphrase for private key
- **certificate**: _Secret_ - Certificate generated by ITOC support
- **disable_ssl_verification**: Set to `true` when connecting to a locally hosted sandbox instance

Settings marked as _Secret_ need to be added to the app secrets.

## Jobs

This MESH connection is controlled by the feature flag `mesh_jobs` which needs
to be enabled for the related jobs to connect to MESH, otherwise they will fail
silently.

- **MESHValidateMailboxJob** - This job validates the mailbox with MESH letting
  it know that it is active and the service using it is running. It should run
  every 24 hours. See [Message Exchange for Social Care and Health (MESH) API -
  NHS England Digital](https://digital.nhs.uk/developer/api-catalogue/message-exchange-for-social-care-and-health-api#post-/messageexchange/-mailbox_id-)

- **DPSExport** - Sends vaccination records to DPS for processing via MESH. Runs
  nightly and generates a DPS export for each programme that has unsent records.

## Developing and testing

MESH can be run locally using a Docker container. Clone the [MESH Sandbox repo](https://github.com/NHSDigital/mesh-sandbox) locally and use `docker-compose` to start it:

```
$ docker-compose up
[+] Running 1/0
 ✔ Container mesh_sandbox  Created                                                                                       0.0s
Attaching to mesh_sandbox
mesh_sandbox  | INFO:     Started server process [1]
mesh_sandbox  | INFO:     Waiting for application startup.
mesh_sandbox  | INFO:     | 2024-08-22 14:02:24 | startup auth_mode: full store_mode: file
mesh_sandbox  | INFO:     Application startup complete.
mesh_sandbox  | INFO:     Uvicorn running on https://0.0.0.0:443 (Press CTRL+C to quit)
mesh_sandbox  | INFO:     | 2024-08-22 14:02:26 | begin ping https://localhost/health
mesh_sandbox  | INFO:     | 2024-08-22 14:02:26 | end ping https://localhost/health 200 0.0054
mesh_sandbox  | INFO:     127.0.0.1:46164 - "GET /health HTTP/1.1" 200 OK
```

(I recommend running it in `tmux` as it logs a ping to the health endpoint every
second and can get noisy)

Mavis' development environment is configured to connect to a locally running
sandbox automatically and you can test some of the basic functions using it.

There are several rake tasks that can be used to develop and test MESH features:

```
$ rails -T mesh
bin/rails mesh:ack_message[message]  # Acknowledge message MESH, removing it from inbox
bin/rails mesh:check_inbox           # Check MESH inbox, listing any messages
bin/rails mesh:dps_export            # Export DPS data via MESH
bin/rails mesh:get_message[message]  # Get message from MESH
bin/rails mesh:send_file[to,file]    # Send a file to a mailbox via MESH
bin/rails mesh:validate_mailbox      # Validate MESH mailbox to let MESH know Mavis is up and running
```

## DPS (Data Processing Service) Export

Upstream reporting to other NHSE services is done by sending vaccination events
to DPS via MESH. Here's an example of testing the MESH integration by triggering
the jobs manually:

1. Clear out any existing `DPSExport` records for the programme you want to test with:
   ```
   [1] pry(main)> Programme.find(1).dps_exports.destroy_all
   ```
2. Trigger the job to send vaccination records to DPS:
   ```
   [2] pry(main)> MESHDPSExportJob.perform_now
   Performing MESHDPSExportJob (Job ID: 15ff78e8-3d8e-42c8-af1a-086ab4e77ff7) from GoodJob(default)
   ...
   DPS export (17) for programme (1) sent: 202 - {"message_id":"3F5A532496B341798B698FD44A0155F7"}
   Performed MESHDPSExportJob (Job ID: 15ff78e8-3d8e-42c8-af1a-086ab4e77ff7) from GoodJob(default) in 332.56ms
   ```
3. Confirm a `DPSExport` record was created:
   ```
   [3] pry(main)> Campaign.find(1).dps_exports
   => [#<DPSExport:0x000000014d37cd20
     id: 17,
     message_id: "3F5A532496B341798B698FD44A0155F7",
     status: "accepted",
     filename: "Vaccinations-HPV-2024-08-23.csv",
     sent_at: nil,
     programme_id: 1,
     created_at: Fri, 23 Aug 2024 16:42:29.679686000 BST +01:00,
     updated_at: Fri, 23 Aug 2024 16:42:29.742197000 BST +01:00>]
   ```
4. Confirm the message has arrived using a Rake task:
   ```
   $ MAVIS__MESH__MAILBOX=X26ABC3 MAVIS__MESH__PASSWORD=password rails mesh:check_inbox
   {"messages":["3F5A532496B341798B698FD44A0155F7"],"links":{"self":"/messageexchange/X26ABC3/inbox"},"approx_inbox_count":1}
   ```
5. (Optional) Confirm the export file's contents:
   ```
   $ MAVIS__MESH__MAILBOX=X26ABC3 MAVIS__MESH__PASSWORD=password rails mesh:get_message[3F5A532496B341798B698FD44A0155F7]
   "NHS_NUMBER"|"PERSON_FORENAME"|"PERSON_SURNAME"|"PERSON_DOB"|"PERSON_GENDER_CODE"|"PERSON_POSTCODE"|"DATE_AND_TIME"|"SITE_CODE"|"SITE_CODE_TYPE_URI"|"UNIQUE_ID"|"UNIQUE_ID_URI"|"ACTION_FLAG"|"PERFORMING_PROFESSIONAL_FORENAME"|"PERFORMING_PROFESSIONAL_SURNAME"|"RECORDED_DATE"|"PRIMARY_SOURCE"|"VACCINATION_PROCEDURE_CODE"|"VACCINATION_PROCEDURE_TERM"|"DOSE_SEQUENCE"|"VACCINE_PRODUCT_CODE"|"VACCINE_PRODUCT_TERM"|"VACCINE_MANUFACTURER"|"BATCH_NUMBER"|"EXPIRY_DATE"|"SITE_OF_VACCINATION_CODE"|"SITE_OF_VACCINATION_TERM"|"ROUTE_OF_VACCINATION_CODE"|"ROUTE_OF_VACCINATION_TERM"|"DOSE_AMOUNT"|"DOSE_UNIT_CODE"|"DOSE_UNIT_TERM"|"INDICATION_CODE"|"LOCATION_CODE"|"LOCATION_CODE_TYPE_URI"
   "9992686766"|"Brenton"|"Waters"|"20120818"|"0"|"UC0W 0JL"|"20230609T00000000"|"U1"|"https://fhir.nhs.uk/Id/ods-organization-code"|"496e37d8-d1ab-4e12-a3a3-9c2e136a0504"|"https://manage-vaccinations-in-schools.nhs.uk/vaccination-records"|"new"|""|""|"20240821"|"TRUE"|"761841000"|"Administration of vaccine product containing only Human papillomavirus antigen (procedure)"|"1"|"33493111000001108"|"Gardasil 9 vaccine suspension for injection 0.5ml pre-filled syringes (Merck Sharp & Dohme (UK) Ltd) (product)"|"Merck Sharp & Dohme"|"CD5472"|"20240930"|"368208006"|"Structure of left upper arm (body structure)"|"78421000"|"Intramuscular route (qualifier value)"|"0.5"|"258773002"|"Milliliter (qualifier value)"|""|"123456"|"https://fhir.hl7.org.uk/Id/urn-school-number"
   ...
   ```
6. Acknowledge the message:
   ```
   $ MAVIS__MESH__MAILBOX=X26ABC3 MAVIS__MESH__PASSWORD=password rails mesh:ack_message[3F5A532496B341798B698FD44A0155F7]
   200 - Message acknowledged
   ```
7. Trigger the track message job, and note that the `DPSExport`'s status is changed:
   ```
   [4] pry(main)> MESHTrackDPSExportsJob.perform_now
   Performing MESHTrackDPSExportsJob (Job ID: c7d99e05-1f67-4e76-8140-473a38a79090) from GoodJob(mesh)
   ...
   Performed MESHTrackDPSExportsJob (Job ID: c7d99e05-1f67-4e76-8140-473a38a79090) from GoodJob(mesh) in 50.97ms
   ↳ (pry):3:in `__pry__'
   => [#<DPSExport:0x000000014d2b0158
     id: 17,
     message_id: "3F5A532496B341798B698FD44A0155F7",
     status: "acknowledged",
     filename: "Vaccinations-HPV-2024-08-23.csv",
     sent_at: nil,
     programme_id: 1,
     created_at: Fri, 23 Aug 2024 16:42:29.679686000 BST +01:00,
     updated_at: Fri, 23 Aug 2024 16:48:54.371976000 BST +01:00>]
   ```

The DPS export can also be sent through the cmdline without triggering the job:

```
$ rails mesh:dps_export
D, [2024-08-22T16:12:14.878651 #98067] DEBUG -- :   Flipper feature(mesh_jobs) enabled? true (6.0ms)  [ actors=nil gate_name=boolean ]
I, [2024-08-22T16:12:15.237132 #98067]  INFO -- : DPS export (2) for programme (1) sent: 202 - {"message_id":"B18FA3D33F994615988FE5AFA20143D7"}
```

## Additional resources

- [Message Exchange for Social Care and Health (MESH) API - NHS England Digital](https://digital.nhs.uk/developer/api-catalogue/message-exchange-for-social-care-and-health-api#overview--end-to-end-process-to-integrate-with-mesh-api)
- [Apply for a MESH mailbox - NHS England Digital](https://digital.nhs.uk/services/message-exchange-for-social-care-and-health-mesh/messaging-exchange-for-social-care-and-health-apply-for-a-mailbox) - part of the application form for the MESH mailbox touches on creating a request for a TLS cert
- [Message Exchange for Social Care and Health: certificate guidance - NHS England Digital](https://digital.nhs.uk/services/message-exchange-for-social-care-and-health-mesh/mesh-guidance-hub/certificate-guidance) - more detailed instructions that targets Windows systems, but still useful
