# frozen_string_literal: true

class AddRecordedByToConsent < ActiveRecord::Migration[7.1]
  def change
    add_reference :consents,
                  :recorded_by_user,
                  foreign_key: {
                    to_table: :users
                  }
  end
end
