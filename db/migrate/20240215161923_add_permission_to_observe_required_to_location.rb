# frozen_string_literal: true

class AddPermissionToObserveRequiredToLocation < ActiveRecord::Migration[7.1]
  def change
    add_column :locations, :permission_to_observe_required, :boolean
  end
end
