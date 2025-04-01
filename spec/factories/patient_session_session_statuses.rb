# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_session_session_statuses
#
#  id                 :bigint           not null, primary key
#  status             :integer          default("none_yet"), not null
#  patient_session_id :bigint           not null
#  programme_id       :bigint           not null
#
# Indexes
#
#  idx_on_patient_session_id_programme_id_8777f5ba39  (patient_session_id,programme_id) UNIQUE
#  index_patient_session_session_statuses_on_status   (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
FactoryBot.define do
  factory :patient_session_session_status,
          class: "PatientSession::SessionStatus" do
    patient_session
    programme

    traits_for_enum :status
  end
end
