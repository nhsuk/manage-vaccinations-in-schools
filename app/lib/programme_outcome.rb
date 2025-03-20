# frozen_string_literal: true

class ProgrammeOutcome
  def initialize(
    patients:,
    consent_outcome:,
    triage_outcome:,
    vaccinated_criteria:
  )
    @patients = patients
    @consent_outcome = consent_outcome
    @triage_outcome = triage_outcome
    @vaccinated_criteria = vaccinated_criteria
  end

  STATUSES = [
    VACCINATED = :vaccinated,
    COULD_NOT_VACCINATE = :could_not_vaccinate,
    NONE_YET = :none_yet
  ].freeze

  def vaccinated?(patient, programme:)
    status(patient, programme:) == VACCINATED
  end

  def could_not_vaccinate?(patient, programme:)
    status(patient, programme:) == COULD_NOT_VACCINATE
  end

  def none_yet?(patient, programme:)
    status(patient, programme:) == NONE_YET
  end

  def status(patient, programme:)
    if vaccinated_criteria.vaccinated?(patient, programme:)
      VACCINATED
    elsif programme_could_not_vaccinate?(patient, programme:)
      COULD_NOT_VACCINATE
    else
      NONE_YET
    end
  end

  private

  attr_reader :patients, :consent_outcome, :triage_outcome, :vaccinated_criteria

  def programme_could_not_vaccinate?(patient, programme:)
    consent_outcome.refused?(patient, programme:) ||
      triage_outcome.do_not_vaccinate?(patient, programme:)
  end
end
