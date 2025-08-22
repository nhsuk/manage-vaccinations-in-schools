# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_registration_statuses
#
#  id         :bigint           not null, primary key
#  status     :integer          default("unknown"), not null
#  patient_id :bigint           not null
#  session_id :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_session_id_2ff02d8889            (patient_id,session_id) UNIQUE
#  index_patient_registration_statuses_on_patient_id  (patient_id)
#  index_patient_registration_statuses_on_session_id  (session_id)
#  index_patient_registration_statuses_on_status      (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (session_id => sessions.id) ON DELETE => cascade
#
FactoryBot.define do
  factory :patient_registration_status, class: "Patient::RegistrationStatus" do
    patient
    session
    traits_for_enum :status
  end
end
