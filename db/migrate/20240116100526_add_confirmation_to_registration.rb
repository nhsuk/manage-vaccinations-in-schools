# frozen_string_literal: true

class AddConfirmationToRegistration < ActiveRecord::Migration[7.1]
  def change
    change_table :registrations, bulk: true do |t|
      t.boolean :terms_and_conditions_agreed
      t.boolean :data_processing_agreed
      t.boolean :consent_response_confirmed
    end
  end
end
