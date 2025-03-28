# frozen_string_literal: true

class RemoveHealthAnswersRequireFollowUpFromPatientConsentStatus < ActiveRecord::Migration[
  8.0
]
  def change
    remove_column :patient_consent_statuses,
                  :health_answers_require_follow_up,
                  :boolean,
                  default: false,
                  null: false
  end
end
