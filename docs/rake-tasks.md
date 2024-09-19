# Rake Tasks

## Vaccines

### `vaccines:add_to_programme[programme_id, vaccine_nivs_name]`

- `programme_id` - The ID of the programme.
- `vaccine_nivs_name` - The NIVS name of the vaccine.

This adds a vaccine to a programme.

### `vaccines:seed`

This creates the default set of vaccine records, or if they already exist, updates any existing vaccine records to match the default set.

This is useful for setting up a new production environment, but also gets automatically run by `db:seed`.
