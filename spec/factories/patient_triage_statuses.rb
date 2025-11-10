# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_triage_statuses
#
#  id               :bigint           not null, primary key
#  academic_year    :integer          not null
#  programme_type   :enum             not null
#  status           :integer          default("not_required"), not null
#  vaccine_method   :integer
#  without_gelatine :boolean
#  patient_id       :bigint           not null
#  programme_id     :bigint
#
# Indexes
#
#  idx_on_patient_id_programme_type_academic_year_b66791407e      (patient_id,programme_type,academic_year) UNIQUE
#  index_patient_triage_statuses_on_academic_year_and_patient_id  (academic_year,patient_id)
#  index_patient_triage_statuses_on_status                        (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
FactoryBot.define do
  factory :patient_triage_status, class: "Patient::TriageStatus" do
    patient
    programme { CachedProgramme.sample }
    academic_year { AcademicYear.current }

    traits_for_enum :status
    traits_for_enum :vaccine_method

    trait :safe_to_vaccinate do
      status { "safe_to_vaccinate" }
      injection
      without_gelatine { false }
    end

    trait :safe_to_vaccinate_nasal do
      status { "safe_to_vaccinate" }
      nasal
      without_gelatine { false }
    end

    trait :safe_to_vaccinate_without_gelatine do
      safe_to_vaccinate
      without_gelatine
    end

    trait :without_gelatine do
      without_gelatine { true }
    end
  end
end
