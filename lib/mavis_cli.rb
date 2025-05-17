# frozen_string_literal: true

module MavisCLI
  extend Dry::CLI::Registry

  def self.load_rails
    require File.expand_path("../config/environment", __dir__)
  end
end

require_relative "mavis_cli/generate/cohort_imports"
require_relative "mavis_cli/generate/consents"
