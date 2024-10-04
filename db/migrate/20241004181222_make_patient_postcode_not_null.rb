# frozen_string_literal: true

class MakePatientPostcodeNotNull < ActiveRecord::Migration[7.2]
  def change
    change_column_null :patients, :address_postcode, true
  end
end
