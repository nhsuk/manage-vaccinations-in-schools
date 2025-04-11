# frozen_string_literal: true

module HostingEnvironment
  class << self
    def name
      pull_request ? "review" : ENV.fetch("SENTRY_ENVIRONMENT", "development")
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
