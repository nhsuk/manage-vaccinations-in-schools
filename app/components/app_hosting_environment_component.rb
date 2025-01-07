# frozen_string_literal: true

class AppHostingEnvironmentComponent < ViewComponent::Base
  erb_template <<-ERB
    <div class="app-environment nhsuk-tag--<%= colour %>">
      <div class="nhsuk-width-container">
        <strong class="nhsuk-tag nhsuk-tag--<%= colour %>">
          <%= title %>
        </strong>
        <span><%= t("hosting_environment", name:) %></span>
      </div>
    </div>
  ERB

  def render?
    !Rails.env.production?
  end

  ENVIRONMENT_COLOR = {
    development: "white",
    test: "red",
    qa: "orange",
    preview: "yellow",
    training: "purple"
  }.freeze

  def title
    environment.titleize
  end

  def name
    return title if environment == "qa"

    environment
  end

  def colour
    ENVIRONMENT_COLOR[environment.to_sym]
  end

  def environment
    ENV.fetch("SENTRY_ENVIRONMENT", "development")
  end
end
