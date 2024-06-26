# frozen_string_literal: true

class AppSecondaryNavigationComponent < ViewComponent::Base
  renders_many :items, "Item"

  class Item < ViewComponent::Base
    attr_reader :href, :selected

    def call
      content
    end

    def initialize(href:, selected: false)
      super

      @href = href
      @selected = selected
    end
  end
end
