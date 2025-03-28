# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_consent_statuses
#
#  id                               :bigint           not null, primary key
#  health_answers_require_follow_up :boolean          default(FALSE), not null
#  status                           :integer          default("no_response"), not null
#  patient_id                       :bigint           not null
#  programme_id                     :bigint           not null
#
# Indexes
#
#  index_patient_consent_statuses_on_patient_id_and_programme_id  (patient_id,programme_id) UNIQUE
#  index_patient_consent_statuses_on_status                       (status)
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

    traits_for_enum :status

    trait :health_answers_require_follow_up do
      health_answers_require_follow_up { true }
    end
  end
end
