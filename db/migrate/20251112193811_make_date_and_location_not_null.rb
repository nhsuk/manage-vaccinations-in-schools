# frozen_string_literal: true

class MakeDateAndLocationNotNull < ActiveRecord::Migration[8.1]
  def change
    change_table :gillick_assessments, bulk: true do |t|
      t.change_null :location_id, false
      t.change_null :date, false
      t.change_null :session_date_id, true
    end

    change_table :pre_screenings, bulk: true do |t|
      t.change_null :location_id, false
      t.change_null :date, false
      t.change_null :session_date_id, true
    end
  end
end
