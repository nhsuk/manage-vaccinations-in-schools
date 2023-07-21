class CreateCampaignVaccinesJoinTable < ActiveRecord::Migration[7.0]
  def up
    create_join_table :campaigns, :vaccines do |t|
      t.index %i[campaign_id vaccine_id]
      t.index %i[vaccine_id campaign_id]
    end
    Campaign.all.each do |c|
      c.vaccines << Vaccine.find(c.vaccine_id)
    end
    remove_column :campaigns, :vaccine_id
  end

  def down
    add_reference :campaigns, :vaccine, foreign_key: true
    Campaign.all.includes(:vaccines).each do |c|
      c.update(vaccine_id: c.vaccines.first.id)
    end
    drop_join_table :campaigns, :vaccines
    change_column_null :campaigns, :vaccine_id, false
  end
end
