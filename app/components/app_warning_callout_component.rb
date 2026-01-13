# frozen_string_literal: true

class AppWarningCalloutComponent < ViewComponent::Base
  erb_template <<-ERB
    <div class="nhsuk-card nhsuk-card--warning">
      <div class="nhsuk-card__content">
        <h3 class="nhsuk-card__heading">
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
    </div>
  ERB

  def initialize(heading:, description: nil)
    @heading = heading
    @description = description
  end
end
