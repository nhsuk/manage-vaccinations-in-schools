# frozen_string_literal: true

class RenameTriageToTriages < ActiveRecord::Migration[8.0]
  def up
    rename_table :triage, :triages
  end

  def down
    rename_table :triages, :triage
  end
end
