# frozen_string_literal: true

class AppSecondaryNavigationComponent < ViewComponent::Base
  renders_many :items, "Item"

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
