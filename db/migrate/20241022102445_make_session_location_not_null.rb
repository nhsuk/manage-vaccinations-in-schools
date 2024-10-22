# frozen_string_literal: true

class MakeSessionLocationNotNull < ActiveRecord::Migration[7.2]
  def up
    Session
      .includes(:team)
      .where(location_id: nil)
      .find_each do |session|
        team = session.team

        location =
          Location.create_with(name: "#{team.name} Clinic").find_or_create_by!(
            ods_code: team.ods_code,
            type: :generic_clinic,
            team:
          )

        session.update!(location:)
      end

    change_column_null :sessions, :location_id, false
  end

  def down
    change_column_null :sessions, :location_id, true
  end
end
