# frozen_string_literal: true

class AppCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <<%= top_level_tag %> class="<%= card_classes %>">
      <div class="<%= content_classes %>">
        <%= heading %>

        <% if description.present? %>
          <p class="nhsuk-card__description"><%= description %></p>
        <% end %>

        <% if data.present? %>
          <p class="nhsuk-card__description app-card__data"><%= data %></p>
        <% end %>

        <% if meta.present? %>
          <p class="nhsuk-body-s"><%= meta %></p>
        <% end %>

        <%= content %>
      </div>
    </<%= top_level_tag %>>
  ERB

  renders_one :heading,
              ->(level: 3, size: nil, colour: nil) do
                AppCardHeadingComponent.new(
                  level: level,
                  size: size,
                  colour: colour,
                  feature: @feature,
                  link_to: @link_to
                )
              end

  renders_one :description
  renders_one :data
  renders_one :meta

  def initialize(
    colour: nil,
    link_to: nil,
    feature: false,
    secondary: false,
    compact: false,
    filters: false,
    section: false,
    disabled: false
  )
    @link_to = link_to
    @colour = colour
    @feature = filters || feature
    @secondary = secondary
    @compact = compact
    @filters = filters
    @section = section
    @disabled = disabled
  end

  private

  def top_level_tag = @section ? "section" : "div"

  def card_classes
    [
      "nhsuk-card",
      ("nhsuk-card--clickable" if @link_to.present?),
      ("nhsuk-card--feature" if @feature),
      ("nhsuk-card--secondary" if @secondary),
      "app-card",
      ("app-card--compact" if @compact),
      ("app-card--#{@colour}" if @colour.present?),
      ("app-filters" if @filters),
      ("app-card--disabled" if @disabled)
    ].compact.join(" ")
  end

  def content_classes
    [
      "nhsuk-card__content",
      ("nhsuk-card__content--feature" if @feature),
      ("nhsuk-card__content--secondary" if @secondary)
    ].compact.join(" ")
  end
end
