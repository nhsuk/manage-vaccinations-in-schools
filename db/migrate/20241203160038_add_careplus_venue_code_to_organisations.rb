# frozen_string_literal: true

class AddCareplusVenueCodeToOrganisations < ActiveRecord::Migration[7.2]
  def up
    add_column :organisations, :careplus_venue_code, :string
    Organisation.update_all("careplus_venue_code = ods_code")
    change_column_null :organisations, :careplus_venue_code, false
  end

  def down
    remove_column :organisations, :careplus_venue_code
  end
end
