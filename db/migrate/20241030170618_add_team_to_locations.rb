# frozen_string_literal: true

class AddTeamToLocations < ActiveRecord::Migration[7.2]
  def up
    add_reference :locations, :team

    Location
      .where.not(organisation_id: nil)
      .find_each do |location|
        organisation = Organisation.find(location.organisation_id)
        team_id =
          organisation
            .teams
            .find_or_create_by!(
              name: organisation.name,
              email: organisation.email,
              phone: organisation.phone
            )
            .id
        location.update!(team_id:)
      end

    remove_reference :locations, :organisation, foreign_key: true
    add_foreign_key :locations, :teams
  end

  def down
    add_reference :locations, :organisation, foreign_key: true

    Location
      .where.not(team_id: nil)
      .find_each do |location|
        team = Team.find(location.team_id)
        organisation_id = team.organisation.id
        location.update!(organisation_id:)
      end

    remove_reference :locations, :team, foreign_key: true
  end
end
