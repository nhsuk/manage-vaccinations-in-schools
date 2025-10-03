# frozen_string_literal: true

class AddPatientAlreadyVaccinatedNotificationSentAtToConsents < ActiveRecord::Migration[
  8.0
]
  def change
    add_column :consents,
               :patient_already_vaccinated_notification_sent_at,
               :datetime,
               null: true
  end
end
