# frozen_string_literal: true

class AppPatientTableComponent < ViewComponent::Base
  def initialize(patients, campaign:)
    super

    @patients = patients
    @campaign = campaign
  end

  private

  attr_reader :patients, :campaign

  def heading
    "#{pluralize(patients.count, "child")} in this programme’s cohort"
  end

  def outcome_for(patient:)
    patient_session = patient_session_for(patient:)
    if patient_session.vaccination_administered?
      govuk_tag(text: "Vaccinated", colour: "green")
    elsif patient_session.vaccination_not_administered?
      govuk_tag(text: "Could not vaccinate", colour: "red")
    else
      govuk_tag(text: "No outcome yet", colour: "grey")
    end
  end

  def href_for(patient:)
    patient_session = patient_session_for(patient:)
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
    campaign.patient_sessions.active.order(:created_at).find_by(patient:)
  end
end
