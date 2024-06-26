# frozen_string_literal: true

class RemoveFeedbackRequestSentAtFromConsentForms < ActiveRecord::Migration[7.1]
  def change
    remove_column :consent_forms, :feedback_request_sent_at, :datetime
  end
end
