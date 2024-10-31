# frozen_string_literal: true

class AppPatientCohortTableComponent < ViewComponent::Base
  def initialize(patient)
    super

    @patient = patient
  end

  private

  attr_reader :patient

  delegate :cohort, to: :patient
end
