# frozen_string_literal: true

class AppPatientDetailsComponent < ViewComponent::Base
  def initialize(patient:, session:)
    super

    @patient = patient
    @session = session
  end

  def aged
    "aged #{@patient.dob ? @patient.age : ""}"
  end

  def nhs_number
    @patient.nhs_number.to_s.gsub(/(\d{3})(\d{3})(\d{4})/, "\\1 \\2 \\3")
  end

  def parent_guardian_or_other
    if @patient.parent_relationship == "other"
      @patient.human_enum_name(:parent_relationship_other)
    else
      @patient.human_enum_name(:parent_relationship)
    end
  end
end
