# Rake Tasks

## GP Practices

### `gp_practices:smoke`

Creates a GP practice location suitable for smoke testing in production.

## Schools

### `schools:smoke`

Creates a school location suitable for smoke testing in production.

## Vaccines

### `vaccines:seed[type]`

- `type` - The type of vaccine, either `flu` or `hpv`. (optional)

This creates the default set of vaccine records, or if they already exist, updates any existing vaccine records to match the default set.

This is useful for setting up a new production environment, but also gets automatically run by `db:seed`.
