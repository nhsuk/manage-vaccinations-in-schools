# Managing teams

Each SAIS team in Mavis will have their own set of schools, programmes they administer, and in some cases which schools they administer the programmes to and in which year groups.

## Onboarding for the first time

When first onboarding a new SAIS team, there’s a lot of information to include about it. The process involves creating a YAML file containing all the information about the organisation and using the `onboard` Rake task to add everything in to the service.

### Configuration file structure

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

programmes: [] # A list of programmes (flu, hpv, menacwy, td_ipv)

subteams:
  subteam1: # Identifier to link team with school and links below, not used in app
    name: # Name of the team
    email: # Contact email address
    phone: # Contact phone number
    reply_to_id: # Optional GOV.UK Notify Reply-To UUID

schools:
  subteam1: [] # URNs managed by a particular team

clinics:
  subteam1:
    - name: # Name of the clinic
      address_line_1: # First line of the address
      address_town: # Town of the address
      address_postcode: # Postcode of the address
      ods_code: # Unique ODS code
```

[Example configuration files can be found in the repo][config-onboarding].

[config-onboarding]: /config/onboarding

### Rake task

Once the file has been written you can use the `onboard` Rake task to set everything up in the service.

```sh
$ bundle exec rails onboard[path/to/configuration.yaml]
```

If any validation errors are detected in the file they will be output and nothing will be processed, only if the file is completely valid will anything be processed.

## After onboarding

Once a team has been onboarding, the YAML configuration file can be deleted as it won’t be used again. Instead, a number of command line tools are provided for managing the team.

### Adding new schools to an organisation

The command `schools add-to-organisation` is provided to add new schools to an existing organisation.

```sh
$ bin/mavis schools add-to-organisation ODS_CODE SUBTEAM URNS
```

- `ODS_CODE` refers to the ODS code of the organisation
- `SUBTEAM` refers to the name of the subteam in the organisation
- `URNS` are the URNs of the schools to add

Optionally, it's also possible to customise which programmes are administered at a particular school:

```sh
$ bin/mavis schools add-to-organisation ODS_CODE SUBTEAM URNS --programmes VALUE1,VALUE2,...
```

### Changing administered year groups of a school

Some SAIS teams will administer certain programmes to certain schools outside the normal year groups. For example, flu is often given at special education needs schools in years 12 and 13.

To modify the year groups per programme per school, the follow two commands are provided:

```sh
$ bin/mavis schools add-programme-year-group URN PROGRAMME_TYPE YEAR_GROUPS
$ bin/mavis schools remove-programme-year-group URN PROGRAMME_TYPE YEAR_GROUPS
```

- `URN` refers to the URN of the school to edit
- `PROGRAMME_TYPE` refers to the programme being edited
- `YEAR_GROUPS` are the year groups to add or remove
