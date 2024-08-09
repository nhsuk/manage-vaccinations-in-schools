# frozen_string_literal: true

class AppDevToolsComponent < ViewComponent::Base
  erb_template <<-ERB
    <% unless Rails.env.production? %>
      <div class="app-dev-tools">
        <div class="nhsuk-width-container">
          <h2 class="nhsuk-heading-s">
            Development tools
            <span class="nhsuk-caption-m">Only available in non-production environments</span>
          </h2>
          <%= content %>
        </div>
      </div>
    <% end %>
  ERB

  def render?
    !Rails.env.production? && Flipper.enabled?(:dev_tools)
  end
end
