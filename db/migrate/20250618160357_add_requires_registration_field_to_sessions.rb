# frozen_string_literal: true

class AddRequiresRegistrationFieldToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions,
               :requires_registration,
               :boolean,
               default: true,
               null: false
  end
end
