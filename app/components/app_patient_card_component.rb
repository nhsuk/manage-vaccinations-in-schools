# frozen_string_literal: true

class AppPatientCardComponent < ViewComponent::Base
  def initialize(patient:, session:)
    super

    @patient = patient
    @session = session
  end

  def aged
    "aged #{@patient.dob ? @patient.age : ""}"
  end
end
