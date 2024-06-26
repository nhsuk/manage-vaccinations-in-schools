# frozen_string_literal: true

class AddVaccineIdToCampaign < ActiveRecord::Migration[7.0]
  def up
    add_reference :campaigns, :vaccine, foreign_key: true

    Campaign.all.find_each do |campaign|
      vaccine = Vaccine.find_or_create_by!(name: campaign[:name])
      campaign.update!(vaccine:)
    end

    change_column_null :campaigns, :vaccine_id, false
  end

  def down
    remove_column :campaigns, :vaccine_id
  end
end
