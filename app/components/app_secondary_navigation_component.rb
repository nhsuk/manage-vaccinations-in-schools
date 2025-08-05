# frozen_string_literal: true

class AppSecondaryNavigationComponent < ViewComponent::Base
  renders_many :items, "Item"

  def initialize(classes: nil, attributes: {})
    super
    classes = classes.join(" ") if classes.is_a? Array
    @classes =
      "app-secondary-navigation nhsuk-u-margin-bottom-4#{classes.present? ? " #{classes}" : ""}"
    @attributes =
      attributes.merge(class: @classes, "aria-label": "Secondary menu")
  end

  def selected_item_text
    selected_item = items.find(&:selected)
    selected_item&.call
  end

  class Item < ViewComponent::Base
    def initialize(href:, text: nil, selected: false, ticked: false)
      super

      @href = href
      @text = html_escape(text)
      @selected = selected
      @ticked = ticked
    end

    def call
      content || @text || raise(ArgumentError, "no text or content")
    end

    attr_reader :href, :selected, :ticked
  end
end
