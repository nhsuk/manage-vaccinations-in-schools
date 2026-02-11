# frozen_string_literal: true

class AppImportStatisticsComponent < ViewComponent::Base
  erb_template <<-ERB
    <p><strong>Out of <%= pluralize(@import.rows_count, "record") %> found in the file:</strong></p>
    <ul>
      <li><%= pluralize(@import.new_record_count, "new record") %> imported</li>
      <li><%= pluralize(@import.exact_duplicate_record_count, "duplicate") %> not imported</li>
      <li><%= pluralize(@import.ignored_record_count, "'not vaccinated' record") %> not imported</li>
    </ul>
  ERB

  def initialize(import:)
    @import = import
  end
end
