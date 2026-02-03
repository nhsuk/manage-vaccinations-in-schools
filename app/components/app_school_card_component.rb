# frozen_string_literal: true

class AppSchoolCardComponent < ViewComponent::Base
  def initialize(school, return_to: nil, change_links: {})
    @school = school
    @return_to = return_to
    @change_links = change_links
  end

  def call
    render AppCardComponent.new do |card|
      card.with_heading(level: 3) { "School details" }
      summary_list
    end
  end

  private

  attr_reader :school, :patient_count, :full_width, :return_to, :change_links

  delegate :govuk_button_link_to, :govuk_summary_list, to: :helpers
  delegate :programmes, :year_groups, to: :school

  def summary_list
    render AppSchoolSummaryComponent.new(school, change_links:)
  end
end
