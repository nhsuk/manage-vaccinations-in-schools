# frozen_string_literal: true

class RemoveFromPreScreenings < ActiveRecord::Migration[8.0]
  def up
    change_table :pre_screenings, bulk: true do |t|
      t.remove :feeling_well,
               :knows_vaccination,
               :no_allergies,
               :not_already_had,
               :not_pregnant,
               :not_taking_medication
      t.remove_references :session_date
    end
  end
end
