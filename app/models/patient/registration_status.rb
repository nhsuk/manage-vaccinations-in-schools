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
class Patient::RegistrationStatus < ApplicationRecord
  belongs_to :patient
  belongs_to :session

  has_many :vaccination_records,
           -> { kept.order_by_performed_at },
           through: :patient

  has_many :attendance_records, -> { today }, through: :patient

  enum :status,
       { unknown: 0, attending: 1, not_attending: 2, completed: 3 },
       default: :unknown,
       validate: true

  def attendance_record
    attendance_records.find { it.location_id == session.location_id }
  end

  def assign_status
    self.status = generator.status
  end

  private

  def generator
    @generator ||=
      StatusGenerator::Registration.new(
        patient:,
        session:,
        attendance_record:,
        vaccination_records:
      )
  end
end
