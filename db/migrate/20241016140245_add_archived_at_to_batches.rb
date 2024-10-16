# frozen_string_literal: true

class AddArchivedAtToBatches < ActiveRecord::Migration[7.2]
  def change
    add_column :batches, :archived_at, :datetime
  end
end
