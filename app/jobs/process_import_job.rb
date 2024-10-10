# frozen_string_literal: true

class ProcessImportJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  queue_as :imports

  good_job_control_concurrency_with perform_limit: 1

  def perform(import)
    import.parse_rows!

    return if import.rows_are_invalid?

    import.record!
  end
end
