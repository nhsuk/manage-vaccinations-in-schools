# frozen_string_literal: true

class AppBreadcrumbComponent < ViewComponent::Base
  def initialize(items:, classes: nil, attributes: {})
    super

    @items = items
    @classes = classes
    @attributes = attributes
  end

  def linkable_items
    @items.select { |item| item[:href] }
  end
end
