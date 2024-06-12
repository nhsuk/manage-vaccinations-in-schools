class Card < ApplicationComponent
  include Phlex::Rails::Helpers::LinkTo

  def initialize(link_to: nil, colour: nil)
    super()

    @link_to = link_to
    @colour = colour
  end

  def view_template(&block)
    div(**card_classes) { div(**content_classes, &block) }
  end

  def title(size: "m", &block)
    h2(
      **classes(
        "nhsuk-card__heading",
        "nhsuk-heading-#{size}",
        feature?: "nhsuk-card__heading--feature"
      )
    ) do
      if @link_to
        link_to(@link_to, **classes("nhsuk-card__link"), &block)
      else
        block.call
      end
    end
  end

  def description(&)
    p(**classes("nhsuk-card__description"), &)
  end

  private

  def clickable? = @link_to.present?
  def colour? = @colour.present?
  def feature? = @colour.present?

  def card_classes
    classes(
      "nhsuk-card",
      "app-card",
      colour?: "app-card--#{@colour}",
      clickable?: "nhsuk-card--clickable",
      feature?: "nhsuk-card--feature"
    )
  end

  def content_classes
    classes("nhsuk-card__content", feature?: "nhsuk-card__content--feature")
  end
end
