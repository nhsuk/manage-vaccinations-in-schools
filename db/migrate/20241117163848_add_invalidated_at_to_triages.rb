# frozen_string_literal: true

class AddInvalidatedAtToTriages < ActiveRecord::Migration[7.2]
  def change
    add_column :triage, :invalidated_at, :datetime
  end
end
