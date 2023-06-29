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
    vr = vaccination_records.last

    return :no_outcome if vr.nil?

    vr.administered ? :vaccinated : :could_not_vaccinate
  end
end
