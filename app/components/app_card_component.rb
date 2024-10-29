# frozen_string_literal: true

class AppCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <div class="<%= card_classes %>">
      <div class="<%= content_classes %>">
        <% if heading.present? %>
          <h2 class="<%= heading_classes %>">
            <% if @link_to.present? %>
              <%= link_to @link_to, class: "nhsuk-card__link" do %>
                <%= heading %>
              <% end %>
            <% else %>
              <%= heading %>
            <% end %>
          </h2>
        <% end %>

        <% if description.present? %>
          <p class="nhsuk-card__description"><%= description %></p>
        <% end %>

        <%= content %>
      </div>
    </div>
  ERB

  renders_one :heading
  renders_one :description

  def initialize(colour: nil, link_to: nil, secondary: false, data: false)
    super

    @link_to = link_to
    @colour = colour
    @secondary = secondary
    @data = data
    @feature = colour.present? && !data
  end

  private

  def card_classes
    [
      "nhsuk-card",
      "app-card",
      ("nhsuk-card--feature" if @feature),
      ("app-card--#{@colour}" if @colour.present?),
      ("nhsuk-card--clickable" if @link_to.present?),
      ("nhsuk-card--secondary" if @secondary),
      ("app-card--data" if @data)
    ].compact.join(" ")
  end

  def content_classes
    [
      "nhsuk-card__content",
      ("app-card__content" unless @data),
      ("nhsuk-card__content--feature" if @feature)
    ].compact.join(" ")
  end

  def heading_classes
    [
      "nhsuk-card__heading",
      (@data ? "nhsuk-heading-xs" : "nhsuk-heading-m"),
      ("nhsuk-card__heading--feature" if @feature)
    ].compact.join(" ")
  end
end
