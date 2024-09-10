# frozen_string_literal: true

class AppPatientTableComponent < ViewComponent::Base
  def initialize(patients, programme:)
    super

    @patients = patients
    @programme = programme
  end

  private

  attr_reader :patients, :programme

  def heading
    "#{pluralize(patients.count, "child")} in this programme’s cohort"
  end

  def outcome_for(patient:)
    patient_session = patient_session_for(patient:)
    if patient_session&.vaccination_administered?
      govuk_tag(text: "Vaccinated", colour: "green")
    elsif patient_session&.vaccination_not_administered?
      govuk_tag(text: "Could not vaccinate", colour: "red")
    else
      govuk_tag(text: "No outcome yet", colour: "grey")
    end
  end

  def href_for(patient:)
    patient_session = patient_session_for(patient:)
    return nil if patient_session.nil?

    session = patient_session.session

    tab =
      if patient_session.vaccination_administered?
        "vaccinated"
      elsif patient_session.vaccination_not_administered?
        "could-not"
      else
        "vaccinate"
      end

    session_patient_path(session, patient, section: "vaccinations", tab:)
  end

  def patient_session_for(patient:)
    # TODO: handle multiple patient sessions
    programme.patient_sessions.active.order(:created_at).find_by(patient:)
  end
end
