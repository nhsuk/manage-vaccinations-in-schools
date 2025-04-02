# frozen_string_literal: true

class ChangeBatchExpiryNotNull < ActiveRecord::Migration[8.0]
  def change
    change_column_null :batches, :expiry, true
  end
end
