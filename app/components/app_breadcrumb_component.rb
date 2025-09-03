# frozen_string_literal: true

class AppBreadcrumbComponent < ViewComponent::Base
  def initialize(items:, attributes: {})
    @items = items
    @attributes = attributes
  end

  private

  delegate :govuk_back_link, to: :helpers

  def linkable_items = @items.select { it[:href].present? }
end
