# NHS Personal Demographic Service (PDS) integration

## Initial setup

See [NHS API documentation](nhs_api.md) for setting up the connection to the NHS API platform. Once setup, we should be able to connect to the [PDS FHIR API](https://digital.nhs.uk/developer/api-catalogue/personal-demographics-service-fhir).

## Rake tasks

PDS actions can be triggered through Rake tasks for testing.

```
rails pds:patient:find[nhs_number]    # Retrieve patient using NHS number
```
