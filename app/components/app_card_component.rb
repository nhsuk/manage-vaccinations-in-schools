# frozen_string_literal: true

class AppCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <<%= top_level_tag %> class="<%= card_classes %>">
      <div class="<%= content_classes %>">
        <% if heading.present? %>
          <h<%= @heading_level %> class="<%= heading_classes %>">
            <% if @link_to.present? %>
              <%= link_to @link_to, class: "nhsuk-card__link" do %>
                <%= heading %>
              <% end %>
            <% else %>
              <%= heading %>
            <% end %>
          </h<%= @heading_level %>>
        <% end %>

        <% if description.present? %>
          <p class="nhsuk-card__description"><%= description %></p>
        <% end %>

        <%= content %>
      </div>
    </<%= top_level_tag %>>
  ERB

  renders_one :heading
  renders_one :description

  def initialize(
    colour: nil,
    link_to: nil,
    heading_level: 3,
    secondary: false,
    data: false,
    compact: false,
    filters: false,
    section: false
  )
    super

    @link_to = link_to
    @colour = colour
    @heading_level = heading_level
    @secondary = secondary
    @data = data
    @compact = compact
    @filters = filters
    @section = section

    @feature = (colour.present? && !data && !compact) || filters
  end

  private

  def top_level_tag = @section ? "section" : "div"

  def card_classes
    [
      "nhsuk-card",
      "app-card",
      ("nhsuk-card--feature" if @feature),
      ("app-card--#{@colour}" if @colour.present?),
      ("nhsuk-card--clickable" if @link_to.present?),
      ("nhsuk-card--secondary" if @secondary),
      ("app-card--data" if @data),
      ("app-card--compact" if @compact),
      ("app-filters" if @filters)
    ].compact.join(" ")
  end

  def content_classes
    [
      "nhsuk-card__content",
      ("app-card__content" unless @data),
      ("nhsuk-card__content--feature" if @feature),
      ("nhsuk-card__content--secondary" if @secondary)
    ].compact.join(" ")
  end

  def heading_modifier
    if @data
      "xs"
    elsif @secondary || @compact
      "s"
    else
      "m"
    end
  end

  def heading_classes
    [
      "nhsuk-card__heading",
      "nhsuk-heading-#{heading_modifier}",
      ("nhsuk-card__heading--feature" if @feature)
    ].compact.join(" ")
  end
end
