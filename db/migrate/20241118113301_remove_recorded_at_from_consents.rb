# frozen_string_literal: true

class RemoveRecordedAtFromConsents < ActiveRecord::Migration[7.2]
  def change
    reversible { |dir| dir.up { Consent.where(recorded_at: nil).delete_all } }

    remove_column :consents, :recorded_at, :datetime
  end
end
