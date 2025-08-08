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

require_relative "mavis_cli/clinics/add_to_team"
require_relative "mavis_cli/clinics/create"
require_relative "mavis_cli/generate/cohort_imports"
require_relative "mavis_cli/generate/consents"
require_relative "mavis_cli/generate/vaccination_records"
require_relative "mavis_cli/gias/check_import"
require_relative "mavis_cli/gias/download"
require_relative "mavis_cli/gias/import"
require_relative "mavis_cli/schools/add_programme_year_group"
require_relative "mavis_cli/schools/add_to_team"
require_relative "mavis_cli/schools/remove_programme_year_group"
require_relative "mavis_cli/teams/add_programme"
require_relative "mavis_cli/teams/create_sessions"
require_relative "mavis_cli/teams/list"
require_relative "mavis_cli/vaccination_records/generate_fhir"
require_relative "mavis_cli/vaccination_records/sync"
