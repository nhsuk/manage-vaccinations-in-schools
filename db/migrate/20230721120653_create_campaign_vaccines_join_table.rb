# frozen_string_literal: true

class CreateCampaignVaccinesJoinTable < ActiveRecord::Migration[7.0]
  def up
    create_join_table :campaigns, :vaccines do |t|
      t.index %i[campaign_id vaccine_id]
      t.index %i[vaccine_id campaign_id]
    end
    Campaign.all.find_each { |c| c.vaccines << Vaccine.find(c.vaccine_id) }
    remove_column :campaigns, :vaccine_id
  end

  def down
    add_reference :campaigns, :vaccine, foreign_key: true
    Campaign
      .all
      .includes(:vaccines)
      .find_each { |c| c.update(vaccine_id: c.vaccines.first.id) }
    drop_join_table :campaigns, :vaccines
    change_column_null :campaigns, :vaccine_id, false
  end
end
