# frozen_string_literal: true

class RemoveODSCodeFromGenericClinics < ActiveRecord::Migration[8.0]
  def change
    Location.generic_clinic.update_all(ods_code: nil)
  end
end
