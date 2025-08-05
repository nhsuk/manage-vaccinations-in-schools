# frozen_string_literal: true

class CreateOrganisations < ActiveRecord::Migration[8.0]
  def up
    create_table :organisations do |t|
      t.string :ods_code, null: false
      t.index :ods_code, unique: true
      t.timestamps
    end

    add_reference :teams, :organisation, foreign_key: true

    Team.find_each do |team|
      organisation = Organisation.create!(ods_code: team.ods_code)
      team.update_column(:organisation_id, organisation.id)
    end

    change_table :teams, bulk: true do |t|
      t.remove :ods_code
      t.change_null :organisation_id, false
    end
  end

  def down
    add_column :teams, :ods_code, :string

    Team.find_each do |team|
      organisation = Organisation.find(team.organisation_id)
      team.update_column(:ods_code, organisation.ods_code)
    end

    remove_reference :teams, :organisation

    drop_table :organisations
  end
end
