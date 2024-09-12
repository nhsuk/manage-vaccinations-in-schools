# frozen_string_literal: true

class RemoveRelationshipFromParents < ActiveRecord::Migration[7.2]
  def change
    change_table :parents, bulk: true do |t|
      t.remove :relationship, type: :integer
      t.remove :relationship_other, type: :string
    end
  end
end
