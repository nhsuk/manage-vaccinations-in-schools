# frozen_string_literal: true

class RemoveRecordedAtFromParents < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        Parent
          .where(recorded_at: nil)
          .find_each do |parent|
            parent.parent_relationships.destroy_all
            parent.destroy!
          end
      end
    end

    remove_column :parents, :recorded_at, :datetime
  end
end
