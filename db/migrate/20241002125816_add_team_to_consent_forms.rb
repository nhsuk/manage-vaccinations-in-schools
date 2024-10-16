# frozen_string_literal: true

class AddTeamToConsentForms < ActiveRecord::Migration[7.2]
  def up
    add_reference :consent_forms, :team, foreign_key: true

    ConsentForm.find_each do |consent_form|
      consent_form.update!(team_id: consent_form.session.team_id)
    end

    change_column_null :consent_forms, :team_id, false
  end

  def down
    remove_reference :consent_forms, :team
  end
end
