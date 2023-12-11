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

  def initialize(heading:, feature: false, colour: nil)
    super

    @heading = heading
    @feature = feature

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
      ("app-card--#{@colour}" if @colour.present?)
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
      "nhsuk-heading-m"
    ].compact.join(" ")
  end
end
