# frozen_string_literal: true

class ProcessImportJob < ApplicationJob
  queue_as :imports

  # Sidekiq handles concurrency through queue configuration
  # Only one import should be processed at a time

  def perform(import)
    import.parse_rows!

    return if import.rows_are_invalid?

    import.process!
  end
end
