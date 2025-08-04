# frozen_string_literal: true

module HostingEnvironment
  ENVIRONMENT_COLOUR = {
    production: "blue",
    development: "white",
    review: "purple",
    test: "red",
    qa: "orange",
    preview: "yellow"
  }.freeze

  ENVIRONMENT_THEME_COLOUR = {
    production: "#005eb8",
    development: "#fff",
    review: "#d6cce3",
    test: "#f7d4d1",
    qa: "#ffdc8e",
    preview: "#fff59d"
  }.freeze

  class << self
    def name
      pull_request ? "review" : ENV.fetch("SENTRY_ENVIRONMENT", "development")
    end

    def colour
      ENVIRONMENT_COLOUR[name.to_sym]
    end

    def theme_colour
      ENVIRONMENT_THEME_COLOUR[name.to_sym]
    end

    def title
      pull_request ? "PR #{pull_request}" : name.titleize
    end

    def title_in_sentence
      if pull_request || name == "qa"
        title
      else
        name
      end
    end

    private

    def pull_request
      ENV.fetch("HEROKU_PR_NUMBER", false)
    end
  end
end
