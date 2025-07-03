# frozen_string_literal: true

class AddCIS2InfoToOneTimeTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :one_time_tokens, :cis2_info, :jsonb, null: true
  end
end
