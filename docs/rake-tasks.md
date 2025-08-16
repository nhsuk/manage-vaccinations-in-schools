# Rake Tasks

## `feature_flags:seed`

Set up the feature flags in the database from the configuration.

## `smoke:seed`

Creates a school and a GP practice location suitable for smoke testing in production.

## `vaccines:seed[type]`

- `type` - The type of vaccine, either `flu`, `hpv`, `menacwy` and `td_ipv`. (optional)

This creates the default set of vaccine records, or if they already exist, updates any existing vaccine records to match the default set.

This is useful for setting up a new production environment, but also gets automatically run by `db:seed`.
