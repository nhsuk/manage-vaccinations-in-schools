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

  def initialize(colour: nil, link_to: nil)
    super

    @link_to = link_to
    @colour = colour
  end

  private

  def card_classes
    [
      "nhsuk-card",
      "app-card",
      ("nhsuk-card--feature" if @colour.present?),
      ("app-card--#{@colour}" if @colour.present?),
      ("nhsuk-card--clickable" if @link_to.present?)
    ].compact.join(" ")
  end

  def content_classes
    [
      "nhsuk-card__content",
      "app-card__content",
      ("nhsuk-card__content--feature" if @colour.present?)
    ].compact.join(" ")
  end

  def heading_classes
    [
      "nhsuk-card__heading",
      "nhsuk-heading-m",
      ("nhsuk-card__heading--feature" if @colour.present?)
    ].compact.join(" ")
  end
end
