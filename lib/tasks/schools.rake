# frozen_string_literal: true

namespace :schools do
  desc "Create a school for smoke testing in production."
  task smoke: :environment do
    Location.find_or_create_by!(
      name: "XXX Smoke Test School XXX",
      urn: "XXXXXX",
      type: :school,
      address_line_1: "1 Test Street",
      address_town: "Test Town",
      address_postcode: "TE1 1ST",
      gias_establishment_number: 999_999,
      gias_local_authority_code: 999_999,
      year_groups: [8, 9, 10, 11]
    )
  end
end
