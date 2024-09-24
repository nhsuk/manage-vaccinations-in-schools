# frozen_string_literal: true

class AddProgrammesSessions < ActiveRecord::Migration[7.2]
  def up
    remove_reference :sessions, :programme

    create_join_table :sessions,
                      :programmes,
                      column_options: {
                        foreign_key: true
                      } do |t|
      t.index %i[session_id programme_id], unique: true
    end
  end

  def down
    drop_join_table :sessions, :programmes

    add_reference :sessions, :programme, foreign_key: true
  end
end
