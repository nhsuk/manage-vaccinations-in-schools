# Onboarding

Onboarding a new organisation involves creating a YAML file containing all the information about the organisation and using the `onboard` Rake task to add everything in to the service.

## Configuration file

```yaml
organisation:
  name: # Unique name of the organisation
  email: # Contact email address
  phone: # Contact phone number
  ods_code: # Unique ODS code
  careplus_venue_code: # Venue code used in CarePlus exports
  privacy_notice_url: # URL of a privacy notice shown to parents
  privacy_policy_url: # URL of a privacy policy shown to parents
  reply_to_id: # Optional GOV.UK Notify Reply-To UUID

programmes: [] # A list of programmes, currently only hpv is valid

teams:
  team1: # Identifier to link team with school and links below, not used in app
    name: # Name of the team
    email: # Contact email address
    phone: # Contact phone number
    reply_to_id: # Optional GOV.UK Notify Reply-To UUID

schools:
  team1: [] # URNs managed by a particular team

clinics:
  team1:
    - name: # Name of the clinic
      address_line_1: # First line of the address
      address_town: # Town of the address
      address_postcode: # Postcode of the address
      ods_code: # Unique ODS code
```

[Example configuration files can be found in the repo][config-onboarding].

[config-onboarding]: /config/onboarding

## Rake task

Once the file has been written you can use the `onboard` Rake task to set everything up in the service.

```sh
$ bundle exec rails onboard[path/to/configuration.yaml]
```

If any validation errors are detected in the file they will be output and nothing will be processed, only if the file is completely valid will anything be processed.
