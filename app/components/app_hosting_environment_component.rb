# frozen_string_literal: true

class AppHostingEnvironmentComponent < ViewComponent::Base
  erb_template <<-ERB
    <div class="app-environment nhsuk-tag--<%= colour %>">
      <div class="nhsuk-width-container">
        <strong class="nhsuk-tag nhsuk-tag--<%= colour %>">
          <%= title %>
        </strong>
        <span><%= t("hosting_environment", name: title_in_sentence) %></span>
      </div>
    </div>
  ERB

  def render? = !Rails.env.production?

  delegate :title, :title_in_sentence, to: :HostingEnvironment

  ENVIRONMENT_COLOR = {
    development: "white",
    review: "purple",
    test: "red",
    qa: "orange",
    preview: "yellow"
  }.freeze

  def colour
    ENVIRONMENT_COLOR[HostingEnvironment.name.to_sym]
  end
end
