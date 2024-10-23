# Rake Tasks

## Clinics

### `clinics:create[name,address,town,postcode,ods_code,team_ods_code]`

- `name` - The name of the clinic.
- `address` - The first line of the address.
- `town` - The town of the clinic.
- `postcode` - The postcode of the clinic.
- `ods_code` - The ODS code of the clinic.
- `team_ods_code` - The ODS code of the team.

If none of the arguments are provided (`rake clinics:create`), the user will be prompted for responses.

This creates a new clinic location and attaches it to a team.

## Schools

### `schools:add_to_team[ods_code,urn,...]`

- `ods_code` - The ODS code of the team.
- `urn` - The URN of the school to add, can be added multiple times.

This adds a school or schools to the list of schools that a particular team manages.

## Teams

### `teams:create_hpv[email,name,phone,ods_code,privacy_policy_url,reply_to_id]`

- `email` - The email address of the team.
- `name` - The unique name of the team.
- `phone` - The phone number of the team.
- `ods_code` - The unique ODS code for the team.
- `privacy_policy_url` - The URL of the team’s privacy policy (optional).
- `reply_to_id` - The team’s GOV.UK Notify reply to UUID (optional).

If none of the arguments are provided (`rake teams:create_hpv`), the user will be prompted for responses.

This creates a new team with an HPV programme.

## Users

### `users:create[email,password,given_name,family_name,team_ods_code]`

- `email` - The email address of the new user.
- `password` - The password of the new user.
- `given_name` - The first name of the new user.
- `family_name` - The last name of the new user.
- `team_ods_code` - The ODS code for the team they belong to.

If none of the arguments are provided (`rake users:create`), the user will be prompted for responses.

This creates a new user and adds them to a team.

## Vaccines

### `vaccines:seed[type]`

- `type` - The type of vaccine, either `flu` or `hpv`. (optional)

This creates the default set of vaccine records, or if they already exist, updates any existing vaccine records to match the default set.

This is useful for setting up a new production environment, but also gets automatically run by `db:seed`.
