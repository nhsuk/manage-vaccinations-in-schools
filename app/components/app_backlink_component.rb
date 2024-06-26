# frozen_string_literal: true

class AppBacklinkComponent < ViewComponent::Base
  def initialize(href:, name:, classes: nil, attributes: {})
    super

    @href = href
    @name = name
    classes = classes.join(" ") if classes.is_a? Array
    @classes = "nhsuk-width-container#{classes.present? ? " #{classes}" : ""}"
    @attributes = attributes.merge(class: @classes)
  end
end
