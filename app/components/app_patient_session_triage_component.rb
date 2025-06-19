# frozen_string_literal: true

class AppPatientSessionTriageComponent < ViewComponent::Base
  def initialize(patient_session, programme:, triage:)
    super

    @patient_session = patient_session
    @programme = programme
    @triage = triage
  end

  def render?
    triage_status && !triage_status.not_required?
  end

  private

  attr_reader :patient_session, :programme, :triage

  delegate :patient, :session, to: :patient_session

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
        .find_by(programme:)
  end

  def latest_triage
    @latest_triage ||=
      patient
        .triages
        .not_invalidated
        .includes(:performed_by)
        .order(created_at: :desc)
        .find_by(programme:)
  end

  delegate :status, to: :triage_status
end
