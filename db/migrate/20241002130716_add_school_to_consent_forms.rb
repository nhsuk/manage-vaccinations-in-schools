# frozen_string_literal: true

class AddSchoolToConsentForms < ActiveRecord::Migration[7.2]
  def up
    add_reference :consent_forms, :school, foreign_key: { to_table: :locations }

    ConsentForm.find_each do |consent_form|
      consent_form.update!(location_id: consent_form.session.team_id)
    end

    change_column_null :consent_forms, :location_id, false

    rename_column :consent_forms, :location_confirmed, :school_confirmed
  end

  def down
    rename_column :consent_forms, :school_confirmed, :location_confirmed
    change_column_null :consent_forms, :location_id, true
    remove_reference :consent_forms, :school
  end
end
