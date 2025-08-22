# frozen_string_literal: true

class AppBreadcrumbComponent < ViewComponent::Base
  def initialize(items:, attributes: {})
    super

    @items = items
    @attributes = attributes
  end

  def linkable_items
    @items.select { |item| item[:href] }
  end
end
