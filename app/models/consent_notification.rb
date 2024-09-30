# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_notifications
#
#  id           :bigint           not null, primary key
#  reminder     :boolean          not null
#  sent_at      :datetime         not null
#  patient_id   :bigint           not null
#  programme_id :bigint           not null
#
# Indexes
#
#  index_consent_notifications_on_patient_id                   (patient_id)
#  index_consent_notifications_on_patient_id_and_programme_id  (patient_id,programme_id)
#  index_consent_notifications_on_programme_id                 (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#
class ConsentNotification < ApplicationRecord
  belongs_to :patient
  belongs_to :programme

  def self.create_and_send!(patient:, programme:, session:, reminder:)
    # We create a record in the database first to avoid sending duplicate emails/texts.
    # If a problem occurs while the emails/texts are sent, they will be in the job
    # queue and restarted at a later date.

    ConsentNotification.create!(programme:, patient:, reminder:)

    patient.parents.each do |parent|
      ConsentMailer
        .with(parent:, patient:, programme:, session:)
        .send(reminder ? :reminder : :request)
        .deliver_later

      TextDeliveryJob.perform_later(
        reminder ? :consent_reminder : :consent_request,
        parent:,
        patient:,
        programme:,
        session:
      )
    end

    if reminder
      patient.update!(consent_reminder_sent_at: Time.zone.now)
    else
      patient.update!(consent_request_sent_at: Time.zone.now)
    end
  end
end
