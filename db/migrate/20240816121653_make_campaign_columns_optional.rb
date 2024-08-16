# frozen_string_literal: true

class MakeCampaignColumnsOptional < ActiveRecord::Migration[7.1]
  def change
    change_table :campaigns, bulk: true do |t|
      t.change_null :academic_year, true
      t.change_null :name, true
      t.change_null :type, true
    end
  end
end
