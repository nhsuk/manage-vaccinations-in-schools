# frozen_string_literal: true

class RemoveNotNullFromCareplusVenueCodeOnTeams < ActiveRecord::Migration[8.1]
  def change
    change_column_null :teams, :careplus_venue_code, true
  end
end
