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

  def parent_guardian_or_other
    if @patient.parent_relationship == "other"
      @patient.parent_relationship_other.humanize
    else
      @patient.parent_relationship.humanize
    end
  end
end
