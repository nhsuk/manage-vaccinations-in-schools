class AppCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <div class="<%= card_classes %>">
      <div class="<%= content_classes %>">
        <h2 class="<%= heading_classes %>">
          <% if @link_to.present? %>
            <%= link_to @link_to, class: "nhsuk-card__link" do %>
              <%= @heading %>
            <% end %>
          <% else %>
            <%= @heading %>
          <% end %>
        </h2>

        <div class="nhsuk-card__description">
          <%= content %>
        </div>
      </div>
    </div>
  ERB

  def initialize(
    heading:,
    heading_size: "m",
    feature: false,
    colour: nil,
    card_classes: nil,
    link_to: nil
  )
    super

    @heading = heading
    @heading_size = heading_size
    @feature = feature
    @card_classes = card_classes
    @link_to = link_to

    @colour = colour
  end

  def render?
    content.present?
  end

  private

  def card_classes
    [
      "nhsuk-card",
      ("nhsuk-card--feature" if @feature),
      ("app-card--#{@colour}" if @colour.present?),
      ("nhsuk-card--clickable" if @link_to.present?),
      @card_classes
    ].compact.join(" ")
  end

  def content_classes
    [
      "nhsuk-card__content",
      ("nhsuk-card__content--feature" if @feature)
    ].compact.join(" ")
  end

  def heading_classes
    [
      "nhsuk-card__heading",
      ("nhsuk-card__heading--feature" if @feature),
      ("nhsuk-heading-#{@heading_size}" if @heading_size)
    ].compact.join(" ")
  end
end
