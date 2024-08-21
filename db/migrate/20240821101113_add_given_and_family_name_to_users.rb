# frozen_string_literal: true

class AddGivenAndFamilyNameToUsers < ActiveRecord::Migration[7.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :given_name, null: false, default: ""
      t.string :family_name, null: false, default: ""
    end

    User
      .where.not(full_name: [nil, ""])
      .find_each do |user|
        *given_names, family_name = user.full_name.split
        user.update!(given_name: given_names.join(" "), family_name:)
      end

    change_table :users, bulk: true do |t|
      t.change_default :given_name, from: "", to: nil
      t.change_default :family_name, from: "", to: nil
    end

    remove_column :users, :full_name, :string
  end
end
