# frozen_string_literal: true

class ProcessImportJob < ApplicationJob
  include SingleConcurrencyConcern

  queue_as :imports

  def perform(import)
    import.parse_rows!

    return if import.rows_are_invalid?

    import.process!
  end
end
