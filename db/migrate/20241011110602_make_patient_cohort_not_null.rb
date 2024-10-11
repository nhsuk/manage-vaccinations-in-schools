# frozen_string_literal: true

class MakePatientCohortNotNull < ActiveRecord::Migration[7.2]
  def change
    change_column_null :patients, :cohort_id, true
  end
end
