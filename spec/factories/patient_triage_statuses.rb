# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_triage_statuses
#
#  id             :bigint           not null, primary key
#  status         :integer          default("not_required"), not null
#  vaccine_method :integer
#  patient_id     :bigint           not null
#  programme_id   :bigint           not null
#
# Indexes
#
#  index_patient_triage_statuses_on_patient_id_and_programme_id  (patient_id,programme_id) UNIQUE
#  index_patient_triage_statuses_on_status                       (status)
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
