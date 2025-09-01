# frozen_string_literal: true

class AppPatientSessionTriageComponent < ViewComponent::Base
  def initialize(patient_session, programme:, triage_form: nil)
    @patient_session = patient_session
    @programme = programme
    @triage_form = triage_form || default_triage_form
  end

  def render?
    triage_status && !triage_status.not_required?
  end

  private

  attr_reader :patient_session, :programme, :triage_form

  delegate :patient, :session, to: :patient_session
  delegate :academic_year, to: :session

  def colour
    I18n.t(status, scope: %i[status triage colour])
  end

  def heading
    "#{programme.name}: #{I18n.t(status, scope: %i[status triage label])}"
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

  def default_triage_form = TriageForm.new(patient_session:, programme:)
end
