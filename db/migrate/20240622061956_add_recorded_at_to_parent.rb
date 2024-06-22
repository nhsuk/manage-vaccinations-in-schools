class AddRecordedAtToParent < ActiveRecord::Migration[7.1]
  def change
    add_column :parents, :recorded_at, :datetime
  end
end
