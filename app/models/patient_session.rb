# == Schema Information
#
# Table name: patient_sessions
#
#  id                       :bigint           not null, primary key
#  gillick_competence_notes :text
#  gillick_competent        :boolean
#  state                    :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  patient_id               :bigint           not null
#  session_id               :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_patient_id_and_session_id  (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_session_id_and_patient_id  (session_id,patient_id) UNIQUE
#

class PatientSession < ApplicationRecord
  include PatientSessionStateMachineConcern

  belongs_to :patient
  belongs_to :session
  has_many :vaccination_records

  validates :gillick_competent,
    inclusion: { in: [true, false] },
    on: :edit_gillick
  validates :gillick_competence_notes,
    presence: true,
    on: :edit_gillick

  def consent_response
    patient.consent_response_for_campaign(session.campaign)
  end

  def triage
    patient.triage_for_campaign(session.campaign)
  end

  def vaccination_record
    vaccination_records.last
  end
end
