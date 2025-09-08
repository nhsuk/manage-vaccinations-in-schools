# frozen_string_literal: true

class AppProgrammeTagsComponent < ViewComponent::Base
  def initialize(programmes)
    @programmes = programmes
  end

  def call = safe_join(tags, " ")

  private

  attr_reader :programmes

  def names = programmes.map(&:name).sort

  def tags = names.map { tag.strong(it, class: "nhsuk-tag nhsuk-tag--white") }
end
