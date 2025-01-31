# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_notifications
#
#  id              :bigint           not null, primary key
#  sent_at         :datetime         not null
#  type            :integer          not null
#  patient_id      :bigint           not null
#  programme_id    :bigint           not null
#  sent_by_user_id :bigint
#  session_id      :bigint           not null
#
# Indexes
#
#  index_consent_notifications_on_patient_id                   (patient_id)
#  index_consent_notifications_on_patient_id_and_programme_id  (patient_id,programme_id)
#  index_consent_notifications_on_programme_id                 (programme_id)
#  index_consent_notifications_on_sent_by_user_id              (sent_by_user_id)
#  index_consent_notifications_on_session_id                   (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (sent_by_user_id => users.id)
#  fk_rails_...  (session_id => sessions.id)
#
class ConsentNotification < ApplicationRecord
  include Sendable

  self.inheritance_column = :nil

  belongs_to :patient
  belongs_to :programme
  belongs_to :session

  enum :type,
       { request: 0, initial_reminder: 1, subsequent_reminder: 2 },
       validate: true

  def reminder?
    initial_reminder? || subsequent_reminder?
  end

  def self.create_and_send!(
    patient:,
    programme:,
    session:,
    type:,
    current_user: nil
  )
    parents = patient.parents.select(&:contactable?)

    return if parents.empty?

    # We create a record in the database first to avoid sending duplicate emails/texts.
    # If a problem occurs while the emails/texts are sent, they will be in the job
    # queue and restarted at a later date.

    ConsentNotification.create!(
      programme:,
      patient:,
      session:,
      type:,
      sent_by: current_user
    )

    is_school = session.location.school?

    mail_template =
      :"consent_#{(is_school ? :"school_#{type}" : :"clinic_#{type}")}"

    text_template =
      if type == :request
        mail_template
      elsif is_school
        :consent_school_reminder
      end

    parents.each do |parent|
      EmailDeliveryJob.perform_later(
        mail_template,
        parent:,
        patient:,
        programme:,
        session:,
        sent_by: current_user
      )

      SMSDeliveryJob.perform_later(
        text_template,
        parent:,
        patient:,
        programme:,
        session:,
        sent_by: current_user
      )
    end
  end
end
