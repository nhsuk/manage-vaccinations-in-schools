# frozen_string_literal: true

class RemoveSessionDateFromGillickAssessmentsAndPreScreenings < ActiveRecord::Migration[
  8.1
]
  def up
    remove_reference :gillick_assessments, :session_date
    remove_reference :pre_screenings, :session_date
  end
end
