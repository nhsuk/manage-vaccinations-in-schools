class AddFeedbackRequestSentAtToConsentForms < ActiveRecord::Migration[7.1]
  def change
    add_column :consent_forms, :feedback_request_sent_at, :datetime
  end
end
