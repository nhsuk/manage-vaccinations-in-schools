# frozen_string_literal: true

class AddPhoneReceiveUpdatesToParents < ActiveRecord::Migration[7.2]
  def change
    add_column :parents,
               :phone_receive_updates,
               :boolean,
               default: false,
               null: false
    add_column :consent_forms,
               :parent_phone_receive_updates,
               :boolean,
               default: false,
               null: false
  end
end
