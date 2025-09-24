# frozen_string_literal: true

class AppImportErrorsComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new(feature: true) do |card| %>
      <% card.with_heading(level: 2, colour: "red") do %>
        <%= @title %>
      <% end %>

      <%= content %>

      <% if @errors.present? %>
        <div data-testid="import-errors">
          <% @errors.each do |error| %>
            <h3 class="nhsuk-heading-s" data-testid="import-errors__heading">
              <% if error.attribute == :csv %>
                CSV
              <% else %>
                <%= error.attribute.to_s.humanize %>
              <% end %>
            </h3>

            <ul class="nhsuk-list nhsuk-list--bullet" data-testid="import-errors__list">
              <% if error.type.is_a?(Array) %>
                <% error.type.each do |type| %>
                  <li><%= sanitize type %></li>
                <% end %>
              <% else %>
                <li><%= sanitize error.type %></li>
              <% end %>
            </ul>
          <% end %>
        </div>
      <% end %>
    <% end %>
  ERB

  def initialize(errors: nil, title: "Records could not be imported")
    @errors = errors
    @title = title
  end

  def render? = @errors.present? || content.present?
end
