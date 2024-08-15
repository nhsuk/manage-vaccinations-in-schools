# frozen_string_literal: true

class AddUniqueIndexToCampaigns < ActiveRecord::Migration[7.1]
  def change
    add_index :campaigns, %i[name type academic_year team_id], unique: true
  end
end
