# frozen_string_literal: true

FactoryBot.define do
  factory :patient_changeset do
    association :import, factory: :cohort_import
    row_number { 1 }
    status { :pending }

    pending_changes do
      {
        child: {
          "given_name" => "John",
          "family_name" => "Doe",
          "date_of_birth" => "2010-01-01",
          "address_postcode" => "SW1A 1AA",
          "nhs_number" => nil
        },
        parent_1: {
        },
        parent_2: {
        },
        pds: {
        },
        search_results: []
      }
    end

    after(:build) do |changeset|
      changeset.import_type = changeset.import.class.name
    end

    trait :with_nhs_number do
      after(:build) do |changeset|
        changeset.pending_changes["child"]["nhs_number"] = "1234567890"
      end
    end

    trait :processed do
      status { :processed }
    end
  end
end
