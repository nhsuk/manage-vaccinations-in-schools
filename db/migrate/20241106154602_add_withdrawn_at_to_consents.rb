# frozen_string_literal: true

class AddWithdrawnAtToConsents < ActiveRecord::Migration[7.2]
  def change
    add_column :consents, :withdrawn_at, :datetime
  end
end
