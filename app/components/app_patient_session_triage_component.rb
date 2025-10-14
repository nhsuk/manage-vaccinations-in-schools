# frozen_string_literal: true

class AppPatientSessionTriageComponent < ViewComponent::Base
  def initialize(
    patient:,
    session:,
    programme:,
    current_user:,
    triage_form: nil
  )
    @patient = patient
    @session = session
    @programme = programme
    @current_user = current_user
    @triage_form = triage_form || default_triage_form
  end

  def render?
    triage_status && !triage_status.not_required?
  end

  private

  attr_reader :patient, :session, :programme, :current_user, :triage_form

  delegate :govuk_button_link_to, to: :helpers
  delegate :academic_year, to: :session

  def colour
    I18n.t(status, scope: %i[status triage colour])
  end

  def heading
    status_with_suffix = triage_status.status

    if programme.has_multiple_vaccine_methods?
      vaccine_method = triage_status.vaccine_method
      status_with_suffix += "_#{vaccine_method}" if vaccine_method
    elsif triage_status.without_gelatine
      status_with_suffix += "_without_gelatine"
    end

    "#{programme.name}: #{I18n.t(status_with_suffix, scope: %i[status triage label])}"
  end

  def triage_status
    @triage_status ||=
      patient
        .triage_statuses
        .includes(:consents, :programme, :vaccination_records)
        .find_by(programme:, academic_year:)
  end

  def vaccination_method
    Vaccine.human_enum_name(:method_prefix, triage_status.vaccine_method)
  end

  delegate :status, to: :triage_status

  def latest_triage
    @latest_triage ||=
      TriageFinder.call(
        patient.triages.includes(:performed_by),
        programme_id: programme.id,
        academic_year:
      )
  end

  def default_triage_form
    TriageForm.new(patient:, session:, programme:, current_user:)
  end
end
