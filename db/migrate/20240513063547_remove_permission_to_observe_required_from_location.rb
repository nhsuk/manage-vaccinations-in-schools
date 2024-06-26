# frozen_string_literal: true

class RemovePermissionToObserveRequiredFromLocation < ActiveRecord::Migration[
  7.1
]
  def change
    remove_column :locations, :permission_to_observe_required, :boolean
  end
end
