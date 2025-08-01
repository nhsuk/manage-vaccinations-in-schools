# frozen_string_literal: true

class AddNotifyParentRefusalToConsents < ActiveRecord::Migration[8.0]
  def change
    add_column :consents, :notify_parent_on_refusal, :boolean
  end
end
