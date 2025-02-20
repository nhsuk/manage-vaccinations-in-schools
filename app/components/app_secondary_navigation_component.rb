# frozen_string_literal: true

class AppSecondaryNavigationComponent < ViewComponent::Base
  renders_many :items, "Item"

  def initialize(classes: nil, attributes: {})
    super
    classes = classes.join(" ") if classes.is_a? Array
    @classes = "app-secondary-navigation nhsuk-u-margin-bottom-4#{classes.present? ? " #{classes}" : ""}"
    @attributes = attributes.merge(
      class: @classes,
      "aria-label": "Secondary menu"
    )
  end

  class Item < ViewComponent::Base
    attr_reader :href, :selected

    def call
      content || @text || raise(ArgumentError, "no text or content")
    end

    def initialize(href:, text: nil, selected: false)
      super

      @href = href
      @text = html_escape(text)
      @selected = selected
    end
  end
end
