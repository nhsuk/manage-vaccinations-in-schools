# frozen_string_literal: true

class AddNotifyParentsToConsents < ActiveRecord::Migration[7.2]
  def change
    add_column :consents, :notify_parents, :boolean
  end
end
