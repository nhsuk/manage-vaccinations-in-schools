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
class Patient::RegistrationStatus < ApplicationRecord
  belongs_to :patient_session

  has_one :patient, through: :patient_session
  has_one :session, through: :patient_session

  has_many :vaccination_records,
           -> { kept.order(performed_at: :desc) },
           through: :patient

  has_one :session_date, -> { today }, through: :session, source: :session_dates

  has_many :session_attendances, through: :patient

  enum :status,
       { unknown: 0, attending: 1, not_attending: 2, completed: 3 },
       default: :unknown,
       validate: true

  def session_attendance
    session_attendances.find { it.session_date_id == session_date&.id }
  end

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
