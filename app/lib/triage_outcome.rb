# frozen_string_literal: true

class TriageOutcome
  def initialize(patients:, consent_outcome:, vaccinated_criteria:)
    @patients = patients
    @consent_outcome = consent_outcome
    @vaccinated_criteria = vaccinated_criteria
  end

  STATUSES = [
    SAFE_TO_VACCINATE = :safe_to_vaccinate,
    DO_NOT_VACCINATE = :do_not_vaccinate,
    DELAY_VACCINATION = :delay_vaccination,
    REQUIRED = :required,
    NOT_REQUIRED = :not_required
  ].freeze

  def safe_to_vaccinate?(patient, programme:)
    status(patient, programme:) == SAFE_TO_VACCINATE
  end

  def do_not_vaccinate?(patient, programme:)
    status(patient, programme:) == DO_NOT_VACCINATE
  end

  def delay_vaccination?(patient, programme:)
    status(patient, programme:) == DELAY_VACCINATION
  end

  def required?(patient, programme:)
    status(patient, programme:) == REQUIRED
  end

  def not_required?(patient, programme:)
    status(patient, programme:) == NOT_REQUIRED
  end

  def status(patient, programme:)
    if triage_safe_to_vaccinate?(patient, programme:)
      SAFE_TO_VACCINATE
    elsif triage_do_not_vaccinate?(patient, programme:)
      DO_NOT_VACCINATE
    elsif triage_delay_vaccination?(patient, programme:)
      DELAY_VACCINATION
    elsif triage_required?(patient, programme:)
      REQUIRED
    else
      NOT_REQUIRED
    end
  end

  def consent_needs_triage?(patient, programme:)
    consent_outcome.needs_triage?(patient, programme:)
  end

  def vaccination_history_needs_triage?(patient, programme:)
    vaccinated_criteria.administered_but_not_vaccinated?(patient, programme:)
  end

  private

  attr_reader :patients, :consent_outcome, :vaccinated_criteria

  def triage_safe_to_vaccinate?(patient, programme:)
    triages.dig(patient.id, programme.id) == "ready_to_vaccinate"
  end

  def triage_do_not_vaccinate?(patient, programme:)
    triages.dig(patient.id, programme.id) == "do_not_vaccinate"
  end

  def triage_delay_vaccination?(patient, programme:)
    triages.dig(patient.id, programme.id) == "delay_vaccination"
  end

  def triage_required?(patient, programme:)
    return true if triages.dig(patient.id, programme.id) == "needs_follow_up"

    consent_outcome.given?(patient, programme:) &&
      (
        consent_needs_triage?(patient, programme:) ||
          vaccination_history_needs_triage?(patient, programme:)
      )
  end

  def triages
    @triages ||=
      Triage
        .where(patient: patients)
        .not_invalidated
        .order(:patient_id, :programme_id, created_at: :desc)
        .pluck(
          Arel.sql(
            "DISTINCT ON (patient_id, programme_id) patient_id, programme_id, status"
          )
        )
        .each_with_object({}) do |row, hash|
          hash[row.first] ||= {}
          hash[row.first][row.second] = row.third
        end
  end
end
