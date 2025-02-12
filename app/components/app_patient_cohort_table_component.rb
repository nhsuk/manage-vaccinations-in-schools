# frozen_string_literal: true

class AppPatientCohortTableComponent < ViewComponent::Base
  def initialize(patient)
    super

    @patient = patient
  end

  private

  attr_reader :patient

  delegate :organisation, :year_group, to: :patient
end
