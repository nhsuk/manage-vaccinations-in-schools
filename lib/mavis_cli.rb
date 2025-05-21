module MavisCLI
  def self.load_rails
    require File.expand_path("../../config/environment", __FILE__)
  end
end

require_relative "mavis_cli/generate/cohort_imports"
