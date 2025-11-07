# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_consent_statuses
#
#  id               :bigint           not null, primary key
#  academic_year    :integer          not null
#  programme_type   :enum             not null
#  status           :integer          default("no_response"), not null
#  vaccine_methods  :integer          default([]), not null, is an Array
#  without_gelatine :boolean
#  patient_id       :bigint           not null
#  programme_id     :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_programme_id_academic_year_1d3170e398         (patient_id,programme_id,academic_year) UNIQUE
#  idx_on_patient_id_programme_type_academic_year_89a70c9513       (patient_id,programme_type,academic_year) UNIQUE
#  index_patient_consent_statuses_on_academic_year_and_patient_id  (academic_year,patient_id)
#  index_patient_consent_statuses_on_status                        (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
FactoryBot.define do
  factory :patient_consent_status, class: "Patient::ConsentStatus" do
    patient
    programme
    academic_year { AcademicYear.current }

    traits_for_enum :status

    trait :given do
      # TODO: Avoid using generic `given` trait.
      given_injection_only
    end

    trait :given_injection_only do
      status { "given" }
      vaccine_methods { %w[injection] }
      without_gelatine { false }
    end

    trait :given_nasal_only do
      status { "given" }
      vaccine_methods { %w[nasal] }
      without_gelatine { false }
    end

    trait :given_nasal_or_injection do
      status { "given" }
      vaccine_methods { %w[nasal injection] }
      without_gelatine { false }
    end

    trait :given_without_gelatine do
      given_injection_only
      without_gelatine { true }
    end
  end
end
