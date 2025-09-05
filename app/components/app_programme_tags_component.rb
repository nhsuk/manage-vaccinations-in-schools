# frozen_string_literal: true

class AppProgrammeTagsComponent < ViewComponent::Base
  def initialize(programmes)
    @programmes = programmes
  end

  def call
    safe_join(
      programmes.map do
        tag.strong(it.name, class: "nhsuk-tag nhsuk-tag--white")
      end,
      " "
    )
  end

  private

  attr_reader :programmes
end
