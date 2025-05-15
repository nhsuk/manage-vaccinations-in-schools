# frozen_string_literal: true

class AddSubmittedAtToConsents < ActiveRecord::Migration[8.0]
  def up
    add_column :consents, :submitted_at, :datetime

    Consent
      .includes(:consent_form)
      .find_each do |consent|
        submitted_at = consent.consent_form&.recorded_at || consent.created_at
        consent.update_column(:submitted_at, submitted_at)
      end

    change_column_null :consents, :submitted_at, false
  end

  def down
    remove_column :consents, :submitted_at
  end
end
