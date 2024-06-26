# frozen_string_literal: true

class AddRegistrationIdToPatient < ActiveRecord::Migration[7.1]
  def change
    add_reference :patients, :registration, foreign_key: true
  end
end
