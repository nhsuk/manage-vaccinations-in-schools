# frozen_string_literal: true

class Patient::ProgrammeOutcome
  def initialize(patient)
    @patient = patient
  end

  STATUSES = [
    VACCINATED = :vaccinated,
    COULD_NOT_VACCINATE = :could_not_vaccinate,
    NONE = :none
  ].freeze

  def vaccinated?(programme) = status[programme] == VACCINATED

  def could_not_vaccinate?(programme) = status[programme] == COULD_NOT_VACCINATE

  def none?(programme) = status[programme] == NONE

  def status
    @status ||=
      Hash.new do |hash, programme|
        hash[programme] = programme_status(programme)
      end
  end

  def all
    @all ||=
      Hash.new do |hash, programme|
        hash[programme] = all_by_programme_id.fetch(programme.id, [])
      end
  end

  private

  attr_reader :patient

  delegate :consent_outcome, :triage_outcome, to: :patient

  def programme_status(programme)
    if programme_vaccinated?(programme)
      VACCINATED
    elsif programme_could_not_vaccinate?(programme)
      COULD_NOT_VACCINATE
    else
      NONE
    end
  end

  def programme_vaccinated?(programme)
    VaccinatedCriteria.call(
      programme,
      patient:,
      vaccination_records: all[programme]
    )
  end

  def programme_could_not_vaccinate?(programme)
    consent_outcome.refused?(programme) ||
      triage_outcome.do_not_vaccinate?(programme)
  end

  def all_by_programme_id
    @all_by_programme_id ||=
      patient.vaccination_records.reject(&:discarded?).group_by(&:programme_id)
  end
end
