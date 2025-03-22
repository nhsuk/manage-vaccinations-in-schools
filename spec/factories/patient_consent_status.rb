# frozen_string_literal: true

FactoryBot.define do
  factory :patient_consent_status, class: "Patient::ConsentStatus" do
    patient
    programme

    traits_for_enum :status
  end
end
