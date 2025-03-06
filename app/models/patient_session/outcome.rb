# frozen_string_literal: true

class PatientSession::Outcome
  def initialize(patient_session)
    @patient_session = patient_session
  end

  STATUSES = [
    VACCINATED = :vaccinated,
    COULD_NOT_VACCINATE = :could_not_vaccinate,
    NONE = :none
  ].freeze

  def status
    @status ||= programmes.index_with { programme_status(it) }
  end

  def all
    @all ||=
      Hash.new do |hash, programme|
        hash[programme] = all_by_programme_id.fetch(programme.id, [])
      end
  end

  private

  attr_reader :patient_session

  delegate :consent, :triage, :patient, :programmes, to: :patient_session

  def programme_status(programme)
    if vaccinated?(programme)
      VACCINATED
    elsif could_not_vaccinate?(programme)
      COULD_NOT_VACCINATE
    else
      NONE
    end
  end

  def vaccinated?(programme)
    VaccinatedCriteria.call(
      programme,
      patient:,
      vaccination_records: all[programme]
    )
  end

  def could_not_vaccinate?(programme)
    all[programme].any? { it.not_administered? && !it.retryable_reason? } ||
      consent.status[programme] == PatientSession::Consent::REFUSED ||
      triage.status[programme] == PatientSession::Triage::DO_NOT_VACCINATE
  end

  def all_by_programme_id
    @all_by_programme_id ||=
      patient.vaccination_records.reject(&:discarded?).group_by(&:programme_id)
  end
end
