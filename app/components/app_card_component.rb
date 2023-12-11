class AppCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <div class="<%= card_classes %>">
      <div class="<%= content_classes %>">
        <h2 class="<%= heading_classes %>">
          <%= @heading %>
        </h2>

        <%= content %>
      </div>
    </div>
  ERB

  def initialize(
    heading:,
    heading_size: "m",
    feature: false,
    colour: nil,
    card_classes: nil
  )
    super

    @heading = heading
    @heading_size = heading_size
    @feature = feature
    @card_classes = card_classes

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
