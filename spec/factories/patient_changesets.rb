# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_changesets
#
#  id                    :bigint           not null, primary key
#  import_type           :string           not null
#  matched_on_nhs_number :boolean
#  pds_nhs_number        :string
#  pending_changes       :jsonb            not null
#  row_number            :integer          not null
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
    row_number { 1 }
    status { :pending }

    trait :class_import do
      import { association(:class_import) }
    end

    trait :cohort_import do
      import { association(:cohort_import) }
    end

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
