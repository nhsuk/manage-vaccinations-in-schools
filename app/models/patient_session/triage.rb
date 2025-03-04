# frozen_string_literal: true

class PatientSession::Triage
  def initialize(patient_session)
    @patient_session = patient_session
  end

  STATUSES = [
    SAFE_TO_VACCINATE = :safe_to_vaccinate,
    DO_NOT_VACCINATE = :do_not_vaccinate,
    DELAY_VACCINATION = :delay_vaccination,
    REQUIRED = :required,
    NOT_REQUIRED = :not_required
  ].freeze

  def status
    @status ||= programmes.index_with { programme_status(it) }
  end

  def all(programme:)
    patient.triages.select { it.programme_id == programme.id }
  end

  def latest(programme:)
    latest_by_programme[programme.id]
  end

  private

  attr_reader :patient_session

  delegate :consent, :patient, :programmes, to: :patient_session

  def programme_status(programme)
    if safe_to_vaccinate?(programme:)
      SAFE_TO_VACCINATE
    elsif do_not_vaccinate?(programme:)
      DO_NOT_VACCINATE
    elsif delay_vaccination?(programme:)
      DELAY_VACCINATION
    elsif required?(programme:)
      REQUIRED
    else
      NOT_REQUIRED
    end
  end

  def safe_to_vaccinate?(programme:)
    latest(programme:)&.ready_to_vaccinate?
  end

  def do_not_vaccinate?(programme:)
    latest(programme:)&.do_not_vaccinate?
  end

  def delay_vaccination?(programme:)
    latest(programme:)&.delay_vaccination?
  end

  def required?(programme:)
    latest(programme:)&.needs_follow_up? ||
      consent.latest(programme:).any?(&:triage_needed?) ||
      patient_session.vaccination_partially_administered?(programme:)
  end

  def latest_by_programme
    @latest_by_programme ||=
      patient
        .triages
        .reject(&:invalidated?)
        .group_by(&:programme_id)
        .transform_values { it.max_by(&:created_at) }
  end
end
