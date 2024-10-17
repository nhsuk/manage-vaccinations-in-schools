# frozen_string_literal: true

class AddRegistrationToPatients < ActiveRecord::Migration[7.2]
  def change
    add_column :patients, :registration, :string
  end
end
