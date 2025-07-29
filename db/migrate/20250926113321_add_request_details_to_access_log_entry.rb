# frozen_string_literal: true

class AddRequestDetailsToAccessLogEntry < ActiveRecord::Migration[8.0]
  def change
    add_column :access_log_entries, :request_details, :jsonb
  end
end
