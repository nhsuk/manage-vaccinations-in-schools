# frozen_string_literal: true

class AddTeamToImmunisationImport < ActiveRecord::Migration[7.2]
  def up
    add_reference :immunisation_imports, :team, foreign_key: true

    ImmunisationImport.all.find_each do |immunisation_import|
      immunisation_import.update!(
        team_id: immunisation_import.programme.team_id
      )
    end

    change_column_null :immunisation_imports, :team_id, false
  end

  def down
    remove_reference :immunisation_imports, :team
  end
end
