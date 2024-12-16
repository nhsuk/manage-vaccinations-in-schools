# Rake Tasks

## Access log

### `access_log:for_patient[id]`

Displays the access log for a particular patient identified by their ID.

### `access_log:for_user[email]`

Displays the access log for a particular user identified by an email address.

## Clinics

### `clinics:create[name,address,town,postcode,ods_code,organisation_ods_code]`

- `name` - The name of the clinic.
- `address` - The first line of the address.
- `town` - The town of the clinic.
- `postcode` - The postcode of the clinic.
- `ods_code` - The ODS code of the clinic.
- `organisation_ods_code` - The ODS code of the organisation.

If none of the arguments are provided (`rake clinics:create`), the user will be prompted for responses.

This creates a new clinic location and attaches it to a organisation.

## GP Practices

### `gp_practices:smoke`

Creates a GP practice location suitable for smoke testing in production.

## Schools

### `schools:add_to_organisation[ods_code,team_name,urn,...]`

- `ods_code` - The ODS code of the organisation.
- `team_name` - The name of the team in the organisation.
- `urn` - The URN of the school to add, can be added multiple times.

This adds a school or schools to the list of schools that a particular organisation manages.

## Teams

### `teams:create[ods_code,name,email,phone]`

- `ods_code` - The ODS code of the organisation.
  `name` - The unique name of the team.
- `email` - The email address of the team.
- `phone` - The phone number of the team.

If none of the arguments are provided (`rake teams:create`), the user will be prompted for responses.

This creates a new team within an organisation.

## Users

### `users:create[email,password,given_name,family_name,organisation_ods_code]`

- `email` - The email address of the new user.
- `password` - The password of the new user.
- `given_name` - The first name of the new user.
- `family_name` - The last name of the new user.
- `organisation_ods_code` - The ODS code for the organisation they belong to.

If none of the arguments are provided (`rake users:create`), the user will be prompted for responses.

This creates a new user and adds them to a organisation.

## Vaccines

### `vaccines:seed[type]`

- `type` - The type of vaccine, either `flu` or `hpv`. (optional)

This creates the default set of vaccine records, or if they already exist, updates any existing vaccine records to match the default set.

This is useful for setting up a new production environment, but also gets automatically run by `db:seed`.
