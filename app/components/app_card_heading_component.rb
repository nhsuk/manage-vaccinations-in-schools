# frozen_string_literal: true

class AppCardHeadingComponent < ViewComponent::Base
  def initialize(level: 3, size: nil, colour: nil, feature: false, link_to: nil)
    @level = level
    @size = size
    @colour = colour
    @feature = colour.present? || feature
    @link_to = link_to
  end

  def call
    content_tag(:"h#{@level}", class: heading_classes) do
      if @link_to.present?
        link_to(@link_to, class: "nhsuk-card__link") { content }
      else
        content
      end
    end
  end

  private

  def heading_modifier
    return @size if @size.present?

    if @level >= 4
      "s"
    else
      "m"
    end
  end

  def heading_classes
    [
      "nhsuk-card__heading",
      "nhsuk-heading-#{heading_modifier}",
      ("nhsuk-card__heading--feature" if @feature),
      ("app-card__heading--#{@colour}" if @colour)
    ].compact.join(" ")
  end
end
