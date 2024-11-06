# frozen_string_literal: true

class AddInvalidatedAtToConsents < ActiveRecord::Migration[7.2]
  def change
    add_column :consents, :invalidated_at, :datetime
  end
end
