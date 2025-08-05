# frozen_string_literal: true

class RenameConsentNotifyParents < ActiveRecord::Migration[8.0]
  def change
    rename_column :consents, :notify_parents, :notify_parents_on_vaccination
  end
end
