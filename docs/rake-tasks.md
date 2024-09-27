# Rake Tasks

## Programmes

### `programmes:create[type]`

- `type` - Either `flu` or `hpv`.

This creates a new programme.

## Schools

### `schools:add_to_team[team_id,urn]`

- `team_id` - The ID of the team.
- `urn` - The URN of the school to add.

This adds a school to the list of schools that a particular team manages.

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

## Vaccines

### `vaccines:add_to_programme[programme_id, vaccine_nivs_name]`

- `programme_id` - The ID of the programme.
- `vaccine_nivs_name` - The NIVS name of the vaccine.

This adds a vaccine to a programme.

### `vaccines:seed`

This creates the default set of vaccine records, or if they already exist, updates any existing vaccine records to match the default set.

This is useful for setting up a new production environment, but also gets automatically run by `db:seed`.
