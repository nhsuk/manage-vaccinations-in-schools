# frozen_string_literal: true

# == Schema Information
#
# Table name: session_notifications
#
#  id           :bigint           not null, primary key
#  sent_at      :datetime         not null
#  session_date :date             not null
#  type         :integer          not null
#  patient_id   :bigint           not null
#  session_id   :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_session_id_session_date_f7f30a3aa3  (patient_id,session_id,session_date)
#  index_session_notifications_on_patient_id             (patient_id)
#  index_session_notifications_on_session_id             (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (session_id => sessions.id)
#
class SessionNotification < ApplicationRecord
  self.inheritance_column = :nil

  belongs_to :patient
  belongs_to :session

  enum :type,
       %w[
         school_reminder
         clinic_initial_invitation
         clinic_subsequent_invitation
       ],
       validate: true

  def self.create_and_send!(patient_session:, session_date:, type:)
    # We create a record in the database first to avoid sending duplicate emails/texts.
    # If a problem occurs while the emails/texts are sent, they will be in the job
    # queue and restarted at a later date.

    patient = patient_session.patient
    session = patient_session.session

    SessionNotification.create!(patient:, session:, session_date:, type:)

    if type == :school_reminder
      patient_session.consents_to_send_communication.each do |consent|
        SessionMailer
          .with(consent:, patient_session:)
          .school_reminder
          .deliver_later

        TextDeliveryJob.perform_later(
          :session_reminder,
          consent:,
          patient_session:
        )
      end
    else
      patient_session.patient.parents.each do |parent|
        SessionMailer.with(parent:, patient_session:).send(type).deliver_later
      end
    end
  end
end
