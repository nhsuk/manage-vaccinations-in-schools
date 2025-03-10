# frozen_string_literal: true

class PatientSession::SessionOutcome
  def initialize(patient_session)
    @patient_session = patient_session
  end

  STATUSES = [
    VACCINATED = :administered,
    ALREADY_HAD = :already_had,
    HAD_CONTRAINDICATIONS = :contraindications,
    REFUSED = :refused,
    ABSENT_FROM_SCHOOL = :absent_from_school,
    ABSENT_FROM_SESSION = :absent_from_session,
    UNWELL = :not_well,
    NONE = :none
  ].freeze

  def vaccinated?(programme) = status[programme] == VACCINATED

  def not_vaccinated?(programme) =
    status[programme] != VACCINATED && status[programme] != NONE

  def none?(programme) = status[programme] == NONE

  def status
    @status ||= programmes.index_with { programme_status(it) }
  end

  def all
    @all ||=
      Hash.new do |hash, programme|
        hash[programme] = all_by_programme_id.fetch(programme.id, [])
      end
  end

  def latest
    @latest ||=
      Hash.new do |hash, programme|
        hash[programme] = all[programme].max_by(&:created_at)
      end
  end

  private

  attr_reader :patient_session

  delegate :patient, :session, :programmes, to: :patient_session
  delegate :consent_outcome, :triage_outcome, to: :patient

  def programme_status(programme)
    if (vaccination_record = latest[programme])
      vaccination_record.outcome.to_sym
    elsif consent_outcome.refused?(programme)
      REFUSED
    elsif triage_outcome.do_not_vaccinate?(programme)
      HAD_CONTRAINDICATIONS
    else
      NONE
    end
  end

  def all_by_programme_id
    @all_by_programme_id ||=
      patient
        .vaccination_records
        .reject(&:discarded?)
        .select { it.session_id == session.id }
        .group_by(&:programme_id)
  end
end
