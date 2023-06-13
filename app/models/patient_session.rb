# == Schema Information
#
# Table name: patient_sessions
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  patient_id :bigint           not null
#  session_id :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_patient_id_and_session_id  (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_session_id_and_patient_id  (session_id,patient_id) UNIQUE
#
class PatientSession < ApplicationRecord
  belongs_to :patient
  belongs_to :session
  has_many :vaccination_records

  def outcome
    # Temporary, while we're not recording separate vaccination records
    patient.seen == "Vaccinated" ? :vaccinated : :no_outcome

    # TODO: Uncomment this when we're recording separate vaccination records
    # vaccination_records.last.present? ? :vaccinated : :no_outcome
  end
end
