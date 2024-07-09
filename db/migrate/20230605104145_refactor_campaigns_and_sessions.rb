# frozen_string_literal: true

class RefactorCampaignsAndSessions < ActiveRecord::Migration[7.0]
  def up
    rename_table :schools, :locations
    change_table :locations, bulk: true do |t|
      t.remove_index "urn"
      t.remove :urn
      t.remove :maximum_age
      t.remove :minimum_age
      t.remove :phase
      t.remove :type
      t.remove :detailed_type
    end

    rename_table :campaigns, :sessions
    create_table :campaigns do |t|
      t.string :name, null: false

      t.timestamps
    end
    execute <<~SQL
      INSERT INTO campaigns (name, created_at, updated_at)
      SELECT DISTINCT type as name, created_at, updated_at FROM sessions
    SQL
    change_table :sessions, bulk: true do |t|
      t.text "name"

      t.remove :location_type
      t.change :location_id, :bigint

      t.references :campaign
    end

    execute <<~SQL
      UPDATE sessions
      SET campaign_id = (SELECT id FROM campaigns WHERE type = sessions.type)
    SQL

    execute <<~SQL
      UPDATE campaigns
      SET name = 'HPV' WHERE name = '0'
    SQL

    execute <<~SQL
      UPDATE sessions
      SET name = (SELECT name FROM campaigns WHERE id = sessions.campaign_id) || ' session at ' || (SELECT name FROM locations WHERE id = sessions.location_id)
    SQL

    change_table :sessions, bulk: true do |t|
      t.remove :type
      t.change_null :campaign_id, false
      t.change_null :name, false
    end

    change_table :campaigns_children, bulk: true do |t|
      t.remove_index %w[child_id campaign_id]
      t.remove_index %w[campaign_id child_id]
      t.rename :campaign_id, :session_id
      t.index %w[session_id child_id],
              name: "index_campaigns_children_on_session_id_and_child_id",
              unique: true
      t.index %w[child_id session_id],
              name: "index_campaigns_children_on_child_id_and_session_id",
              unique: true
    end

    rename_table :campaigns_children, :children_sessions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
