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
  has_one :session, through: :patient_session

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
    self.status =
      if status_should_be_completed?
        :completed
      elsif status_should_be_attending?
        :attending
      elsif status_should_be_not_attending?
        :not_attending
      else
        :unknown
      end
  end

  private

  delegate :academic_year, to: :session

  def status_should_be_completed?
    patient_session.programmes.all? do |programme|
      vaccination_records.any? do
        it.programme_id == programme.id &&
          it.session_id == patient_session.session_id
      end
    end
  end

  def status_should_be_attending?
    session_attendance&.attending
  end

  def status_should_be_not_attending?
    session_attendance&.attending == false
  end
end
