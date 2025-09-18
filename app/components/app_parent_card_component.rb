# frozen_string_literal: true

class AppParentCardComponent < ViewComponent::Base
  def initialize(parent_relationship:, change_links: {})
    @parent_relationship = parent_relationship
    @change_links = change_links
  end

  def call
    render AppCardComponent.new do |card|
      card.with_heading(level: 2) { "Parent or guardian" }
      render AppParentSummaryComponent.new(parent_relationship:, change_links:)
    end
  end

  private

  attr_reader :parent_relationship, :change_links
end
