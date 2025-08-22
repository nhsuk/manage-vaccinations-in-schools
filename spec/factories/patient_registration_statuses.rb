# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_registration_statuses
#
#  id                 :bigint           not null, primary key
#  status             :integer          default("unknown"), not null
#  patient_session_id :bigint           not null
#
# Indexes
#
#  index_patient_registration_statuses_on_patient_session_id  (patient_session_id) UNIQUE
#  index_patient_registration_statuses_on_status              (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :patient_registration_status, class: "Patient::RegistrationStatus" do
    patient_session

    traits_for_enum :status
  end
end
