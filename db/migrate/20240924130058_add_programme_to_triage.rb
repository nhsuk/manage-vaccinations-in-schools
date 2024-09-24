# frozen_string_literal: true

class AddProgrammeToTriage < ActiveRecord::Migration[7.2]
  def up
    add_reference :triage, :programme, foreign_key: true

    Triage.all.find_each do |triage|
      triage.update!(
        programme_id: (triage.session.programme || Programme.first).id
      )
    end

    change_column_null :triage, :programme_id, false
  end

  def down
    remove_reference :triage, :programme
  end
end
