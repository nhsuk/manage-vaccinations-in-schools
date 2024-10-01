# frozen_string_literal: true

class ProcessCohortImportJob < ApplicationJob
  queue_as :default

  def perform(programme, cohort_import)
    cohort_import.programme = programme

    cohort_import.parse_rows!
    return if cohort_import.rows_are_invalid?

    cohort_import.process!
  end
end
