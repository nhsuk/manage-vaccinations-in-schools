# frozen_string_literal: true

module MavisCLI
  extend Dry::CLI::Registry

  def self.load_rails
    require_relative "../../config/environment"
  end
end

require_relative "mavis_cli/generate/cohort_imports"
require_relative "mavis_cli/generate/consents"
require_relative "mavis_cli/generate/vaccination_records"
