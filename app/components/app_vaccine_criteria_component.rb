# frozen_string_literal: true

class AppVaccineCriteriaComponent < ViewComponent::Base
  def initialize(vaccine_criteria)
    @vaccine_criteria = vaccine_criteria
  end

  def call
    tag.span(class: "app-vaccine-criteria", data: { value: }) { content }
  end

  private

  attr_reader :vaccine_criteria

  def value
    if vaccine_criteria.without_gelatine
      "without-gelatine"
    elsif vaccine_criteria.vaccine_methods.include?("nasal")
      "nasal"
    end
  end
end
