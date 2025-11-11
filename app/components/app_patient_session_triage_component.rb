# frozen_string_literal: true

class AppPatientSessionTriageComponent < AppPatientSessionSectionComponent
  def initialize(
    patient:,
    session:,
    programme:,
    current_user:,
    triage_form: nil
  )
    super(patient:, session:, programme:)
    @current_user = current_user
    @triage_form = triage_form || default_triage_form
  end

  def render? = consent_status.given? || !triage_status.not_required?

  private

  attr_reader :current_user, :triage_form

  delegate :govuk_button_link_to, to: :helpers

  def programme_type = programme.type

  def resolved_status
    @resolved_status ||= patient_status_resolver.triage
  end

  def triage_status
    @triage_status ||=
      patient
        .triage_statuses
        .includes(:consents, :vaccination_records)
        .find_or_initialize_by(programme_type:, academic_year:)
  end

  def consent_status
    patient.consent_status(programme:, academic_year:)
  end

  def vaccination_method
    Vaccine.human_enum_name(:method_prefix, triage_status.vaccine_method)
  end

  def latest_triage
    @latest_triage ||=
      TriageFinder.call(
        patient.triages.includes(:performed_by),
        programme_type: programme.type,
        academic_year:
      )
  end

  def default_triage_form
    TriageForm.new(patient:, session:, programme:, current_user:)
  end
end
