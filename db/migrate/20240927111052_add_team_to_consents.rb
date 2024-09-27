# frozen_string_literal: true

class AddTeamToConsents < ActiveRecord::Migration[7.2]
  def up
    add_reference :consents, :team, foreign_key: true

    Consent.all.find_each do |consent|
      consent.update!(team_id: consent.programme.team_id)
    end

    change_column_null :consents, :team_id, false
  end

  def down
    remove_reference :consents, :team
  end
end
