# frozen_string_literal: true

class AppPatientSessionTableComponent < ViewComponent::Base
  def initialize(patient, sessions:)
    super

    @patient = patient
    @sessions = sessions
  end

  private

  attr_reader :patient, :sessions
end
