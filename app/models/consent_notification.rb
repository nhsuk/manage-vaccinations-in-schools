# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_notifications
#
#  id           :bigint           not null, primary key
#  sent_at      :datetime         not null
#  type         :integer          not null
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
  self.inheritance_column = :nil

  belongs_to :patient
  belongs_to :programme

  enum :type, %w[request initial_reminder subsequent_reminder], validate: true

  def reminder?
    initial_reminder? || subsequent_reminder?
  end

  def self.create_and_send!(patient:, programme:, session:, type:)
    # We create a record in the database first to avoid sending duplicate emails/texts.
    # If a problem occurs while the emails/texts are sent, they will be in the job
    # queue and restarted at a later date.

    ConsentNotification.create!(programme:, patient:, type:)

    mailer_action =
      if type == :request
        session.location.clinic? ? :request_for_clinic : :request_for_school
      else
        type
      end

    text_template =
      if type == :request
        if session.location.clinic?
          :consent_request_for_clinic
        else
          :consent_request_for_school
        end
      else
        :consent_reminder
      end

    patient.parents.each do |parent|
      ConsentMailer
        .with(parent:, patient:, programme:, session:)
        .send(mailer_action)
        .deliver_later

      TextDeliveryJob.perform_later(
        text_template,
        parent:,
        patient:,
        programme:,
        session:
      )
    end
  end
end
