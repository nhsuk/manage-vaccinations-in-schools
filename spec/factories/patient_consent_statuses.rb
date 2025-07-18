# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_consent_statuses
#
#  id              :bigint           not null, primary key
#  status          :integer          default("no_response"), not null
#  vaccine_methods :integer          default([]), not null, is an Array
#  patient_id      :bigint           not null
#  programme_id    :bigint           not null
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

    trait :given do
      status { "given" }
      vaccine_methods { %w[injection] }
    end

    trait :given_injection_only do
      status { "given" }
      vaccine_methods { %w[injection] }
    end

    trait :given_nasal_only do
      status { "given" }
      vaccine_methods { %w[nasal] }
    end

    trait :given_nasal_or_injection do
      status { "given" }
      vaccine_methods { %w[nasal injection] }
    end
  end
end
