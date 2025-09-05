# frozen_string_literal: true

class AppCountComponent < ViewComponent::Base
  def initialize(count)
    @count = count
  end

  def call
    tag.span(class: "app-count") do
      safe_join(
        [
          tag.span(" (", class: "nhsuk-u-visually-hidden"),
          @count.to_s,
          tag.span(")", class: "nhsuk-u-visually-hidden")
        ]
      )
    end
  end
end
