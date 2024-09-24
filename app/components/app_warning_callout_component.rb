# frozen_string_literal: true

class AppWarningCalloutComponent < ViewComponent::Base
  erb_template <<-ERB
    <div class="nhsuk-warning-callout">
      <h3 class="nhsuk-warning-callout__label">
        <span role="text">
          <span class="nhsuk-u-visually-hidden">Important: </span>
          <%= @heading %>
        </span>
      </h3>

      <% if @description.present? %>
        <p><%= @description %></p>
      <% end %>

      <%= content %>
    </div>
  ERB

  def initialize(heading:, description: nil)
    super

    @heading = heading
    @description = description
  end
end
