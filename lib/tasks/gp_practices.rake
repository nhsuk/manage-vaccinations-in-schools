# frozen_string_literal: true

namespace :gp_practices do
  desc "Create a GP practice for smoke testing in production."
  task smoke: :environment do
    Location.find_or_create_by!(
      name: "XXX Smoke Test GP XXX",
      ods_code: "Y90001", # https://digital.nhs.uk/developer/api-catalogue/personal-demographics-service-fhir/pds-fhir-api-test-data#production-smoke-testing
      type: :gp_practice
    )
  end
end
