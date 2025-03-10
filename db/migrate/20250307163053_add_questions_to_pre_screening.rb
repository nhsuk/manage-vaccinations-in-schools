# frozen_string_literal: true

class AddQuestionsToPreScreening < ActiveRecord::Migration[8.0]
  def change
    change_table :pre_screenings, bulk: true do |t|
      t.boolean :not_taking_medication, null: false, default: false
      t.boolean :not_pregnant, null: false, default: false
    end

    change_table :pre_screenings, bulk: true do |t|
      t.change_default :not_taking_medication, from: false, to: nil
      t.change_default :not_pregnant, from: false, to: nil
    end
  end
end
