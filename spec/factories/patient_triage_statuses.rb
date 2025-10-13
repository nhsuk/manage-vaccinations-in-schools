# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_triage_statuses
#
#  id               :bigint           not null, primary key
#  academic_year    :integer          not null
#  status           :integer          default("not_required"), not null
#  vaccine_method   :integer
#  without_gelatine :boolean
#  patient_id       :bigint           not null
#  programme_id     :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_programme_id_academic_year_6cf32349df  (patient_id,programme_id,academic_year) UNIQUE
#  index_patient_triage_statuses_on_status                  (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
FactoryBot.define do
  factory :patient_triage_status, class: "Patient::TriageStatus" do
    patient
    programme
    academic_year { Date.current.academic_year }

    traits_for_enum :status

    trait :safe_to_vaccinate do
      status { "safe_to_vaccinate" }
      vaccine_method { "injection" }
    end

    trait :safe_to_vaccinate_nasal do
      status { "safe_to_vaccinate" }
      vaccine_method { "nasal" }
    end
  end
end
