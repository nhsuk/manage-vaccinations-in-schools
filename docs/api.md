# API

In non-production environments an API is available under the base path `/api`.

## `GET /locations`

Gets locations held by the service.

### Parameters

- `is_attached_to_organisation` - one of `true` or `false`
- `status` - one of `open`, `closed` or `unknown`
- `type` - one of `school`, `generic_clinic`, `community_clinic` or `gp_practice`
- `year_groups[]` - an array of year groups which are administered at the location

### Response

- `address_line_1`
- `address_line_2`
- `address_postcode`
- `address_town`
- `gias_establishment_number`
- `gias_local_authority_code`
- `id`
- `is_attached_to_organisation`
- `name`
- `ods_code`
- `status`
- `type`
- `url`
- `urn`
- `year_groups`

## `POST /onboard`

### Body

See [onboarding documentation](managing-teams.md).

## `DELETE /organisations/:ods_code`

Resets an organisation by deleting all associated records.

### Parameters

- `keep_itself` - `true` or `false`, whether to keep the organisation itself and only delete associated information
