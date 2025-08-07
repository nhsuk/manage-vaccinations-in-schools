# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_session_registration_statuses
#
#  id                 :bigint           not null, primary key
#  status             :integer          default("unknown"), not null
#  patient_session_id :bigint           not null
#
# Indexes
#
#  idx_on_patient_session_id_438fc21144                   (patient_session_id) UNIQUE
#  index_patient_session_registration_statuses_on_status  (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id) ON DELETE => cascade
#
class PatientSession::RegistrationStatus < ApplicationRecord
  belongs_to :patient_session

  has_one :patient, through: :patient_session

  has_many :vaccination_records,
           -> { kept.order(performed_at: :desc) },
           through: :patient

  has_one :session_attendance,
          -> { today },
          through: :patient_session,
          source: :session_attendances

  enum :status,
       { unknown: 0, attending: 1, not_attending: 2, completed: 3 },
       default: :unknown,
       validate: true

  def assign_status
    self.status = generator.status
  end

  private

  def generator
    @generator ||=
      StatusGenerator::Registration.new(
        patient_session:,
        session_attendance:,
        vaccination_records:
      )
  end
end
