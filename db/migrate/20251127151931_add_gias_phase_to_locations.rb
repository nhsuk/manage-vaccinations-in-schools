# frozen_string_literal: true

class AddGIASPhaseToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :gias_phase, :integer

    # This is to ensure all locations pass validation, setting the initial value to "not applicable".
    reversible do |direction|
      direction.up { Location.school.update_all(gias_phase: 0) }
    end
  end
end
