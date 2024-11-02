# frozen_string_literal: true

# == Schema Information
#
# Table name: session_notifications
#
#  id              :bigint           not null, primary key
#  sent_at         :datetime         not null
#  session_date    :date             not null
#  type            :integer          not null
#  patient_id      :bigint           not null
#  sent_by_user_id :bigint
#  session_id      :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_session_id_session_date_f7f30a3aa3  (patient_id,session_id,session_date)
#  index_session_notifications_on_patient_id             (patient_id)
#  index_session_notifications_on_sent_by_user_id        (sent_by_user_id)
#  index_session_notifications_on_session_id             (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (sent_by_user_id => users.id)
#  fk_rails_...  (session_id => sessions.id)
#
class SessionNotification < ApplicationRecord
  include Sendable

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

  def clinic_invitation?
    clinic_initial_invitation? || clinic_subsequent_invitation?
  end

  def self.create_and_send!(
    patient_session:,
    session_date:,
    type:,
    current_user: nil
  )
    patient = patient_session.patient
    session = patient_session.session

    contacts =
      if type == :school_reminder
        patient_session.consents_to_send_communication.select(&:contactable?)
      else
        patient.parents.select(&:contactable?)
      end

    return if contacts.empty?

    # We create a record in the database first to avoid sending duplicate emails/texts.
    # If a problem occurs while the emails/texts are sent, they will be in the job
    # queue and restarted at a later date.

    SessionNotification.create!(
      patient:,
      session:,
      session_date:,
      type:,
      sent_by: current_user
    )

    if type == :school_reminder
      contacts.each do |consent|
        SessionMailer
          .with(consent:, patient_session:, sent_by: current_user)
          .school_reminder
          .deliver_later

        TextDeliveryJob.perform_later(
          :session_school_reminder,
          consent:,
          patient_session:,
          sent_by: current_user
        )
      end
    else
      contacts.each do |parent|
        SessionMailer
          .with(parent:, patient_session:, sent_by: current_user)
          .send(type)
          .deliver_later

        TextDeliveryJob.perform_later(
          :"session_#{type}",
          parent:,
          patient_session:,
          sent_by: current_user
        )
      end
    end
  end
end
