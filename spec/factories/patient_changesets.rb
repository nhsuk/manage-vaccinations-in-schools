# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_changesets
#
#  id                    :bigint           not null, primary key
#  data                  :jsonb
#  import_type           :string           not null
#  matched_on_nhs_number :boolean
#  pds_nhs_number        :string
#  pending_changes       :jsonb            not null
#  record_type           :integer          default(1), not null
#  row_number            :integer
#  status                :integer          default("pending"), not null
#  uploaded_nhs_number   :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  import_id             :bigint           not null
#  patient_id            :bigint
#  school_id             :bigint
#
# Indexes
#
#  index_patient_changesets_on_import      (import_type,import_id)
#  index_patient_changesets_on_patient_id  (patient_id)
#  index_patient_changesets_on_status      (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (school_id => locations.id)
#
FactoryBot.define do
  factory :patient_changeset do
    sequence(:row_number) { it }
    status { :pending }

    trait :class_import do
      import { association(:class_import) }
    end

    trait :cohort_import do
      import { association(:cohort_import) }
    end

    data do
      {
        upload: {
          child: {
            given_name: "John",
            family_name: "Dover",
            date_of_birth: "2010-01-01",
            address_postcode: "SW1A 1AA",
            nhs_number: nil
          },
          parent_1: {
          },
          parent_2: {
          },
          pds: {
          },
          academic_year: nil,
          home_educated: nil,
          school_move_source: nil
        },
        search_results: [
          {
            step: :no_fuzzy_with_history,
            result: :no_matches,
            nhs_number: nil,
            created_at: Time.current
          }
        ],
        review: {
          patient: {
          },
          school_move: {
          }
        }
      }
    end

    after(:build) do |changeset|
      changeset.import_type = changeset.import.class.name
    end

    trait :with_nhs_number do
      after(:build) do |changeset|
        changeset.data["upload"]["child"]["nhs_number"] = "1234567890"
      end
    end

    trait :with_pds_match do
      after(:build) do |changeset|
        changeset.data["search_results"] = [
          {
            step: :no_fuzzy_with_history,
            result: :one_match,
            nhs_number: "1234567890",
            created_at: Time.current
          }
        ]
        changeset.pds_nhs_number = "1234567890"
      end
    end

    trait :without_pds_search_attempted do
      after(:build) do |changeset|
        changeset.data["search_results"] = [
          {
            step: :no_fuzzy_with_history,
            result: :no_postcode,
            nhs_number: nil,
            created_at: Time.current
          }
        ]
        changeset.pds_nhs_number = nil
      end
    end

    trait :processed do
      status { :processed }
    end
  end
end
