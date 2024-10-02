# frozen_string_literal: true

class ProcessImportJob < ApplicationJob
  queue_as :default

  def perform(programme, import)
    import.programme = programme

    import.parse_rows!
    return if import.rows_are_invalid?

    import.process!
  end
end
