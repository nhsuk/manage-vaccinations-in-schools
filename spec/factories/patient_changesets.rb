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
#  processed_at          :datetime
#  record_type           :integer          default("new_patient"), not null
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
            nhs_number: nil,
            birth_academic_year: 2010
          },
          parent_1: {
          },
          parent_2: {
          },
          pds: {
          },
          academic_year: AcademicYear.pending,
          home_educated: true,
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

    after(:build) do |changeset, evaluator|
      changeset.import_type = changeset.import.class.name

      if evaluator.patient.present?
        changeset.patient_id = evaluator.patient.id

        changeset.school ||= evaluator.school if evaluator.school.present?

        address_postcode =
          case changeset.record_type
          when "auto_match"
            evaluator.patient.address_postcode
          when changeset.record_type == "import_issue"
            "SW12 4AX"
          else
            changeset.address_postcode
          end

        changeset.data["upload"]["child"] = {
          given_name: evaluator.patient.given_name,
          family_name: evaluator.patient.family_name,
          date_of_birth: evaluator.patient.date_of_birth.to_s,
          address_postcode:,
          nhs_number: evaluator.patient.nhs_number,
          birth_academic_year: evaluator.patient.birth_academic_year
        }
      end
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

    trait :with_school_move do
      after(:build) do |changeset, evaluator|
        changeset.data["review"]["school_move"] = if evaluator.school.present?
          { school_id: evaluator.school.id, home_educated: false }
        else
          { school_id: nil, home_educated: true }
        end
      end
    end

    trait :processed do
      status { :processed }
      processed_at { Time.current }
    end

    trait :new_patient do
      record_type { :new_patient }
    end

    trait :auto_match do
      record_type { :auto_match }
    end

    trait :import_issue do
      record_type { :import_issue }
    end
  end
end
