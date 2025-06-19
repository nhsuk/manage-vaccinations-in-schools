# frozen_string_literal: true

module MavisCLI
  extend Dry::CLI::Registry

  def self.load_rails
    require_relative "../../config/environment"
  end

  def self.progress_bar(total)
    @progress_bar ||=
      ProgressBar.create(
        total: total,
        format: "%a %b\u{15E7}%i %p%% %t",
        progress_mark: " ",
        remainder_mark: "\u{FF65}"
      )
  end
end

require_relative "mavis_cli/generate/cohort_imports"
require_relative "mavis_cli/generate/consents"
require_relative "mavis_cli/generate/fhir_imms_patients"
require_relative "mavis_cli/generate/vaccination_records"
require_relative "mavis_cli/gias/check_import"
require_relative "mavis_cli/gias/download"
require_relative "mavis_cli/gias/import"
