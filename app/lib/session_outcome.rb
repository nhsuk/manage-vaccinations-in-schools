# frozen_string_literal: true

class SessionOutcome
  def initialize(patient_sessions:, register_outcome:, triage_outcome:)
    @patient_sessions = patient_sessions
    @register_outcome = register_outcome
    @triage_outcome = triage_outcome
  end

  STATUSES = [
    VACCINATED = :administered,
    ALREADY_HAD = :already_had,
    HAD_CONTRAINDICATIONS = :contraindications,
    REFUSED = :refused,
    ABSENT_FROM_SCHOOL = :absent_from_school,
    ABSENT_FROM_SESSION = :absent_from_session,
    UNWELL = :not_well,
    NONE_YET = :none_yet
  ].freeze

  def vaccinated?(patient_session, programme:)
    status(patient_session, programme:) == VACCINATED
  end

  def already_had?(patient_session, programme:)
    status(patient_session, programme:) == ALREADY_HAD
  end

  def not_vaccinated?(patient_session, programme:)
    status(patient_session, programme:) != VACCINATED &&
      status(patient_session, programme:) != NONE_YET
  end

  def none_yet?(patient_session, programme:)
    status(patient_session, programme:) == NONE_YET
  end

  def status(patient_session, programme:)
    patient = patient_session.patient

    if (
         outcome =
           vaccination_record_outcomes.dig(
             patient.id,
             patient_session.session_id,
             programme.id
           )
       )
      outcome.to_sym
    elsif patient_session.patient.consent_outcome.refused?(programme)
      REFUSED
    elsif triage_outcome.do_not_vaccinate?(patient, programme:)
      HAD_CONTRAINDICATIONS
    elsif register_outcome.not_attending?(patient_session)
      ABSENT_FROM_SESSION
    else
      NONE_YET
    end
  end

  private

  attr_reader :patient_sessions, :register_outcome, :triage_outcome

  def vaccination_record_outcomes
    @vaccination_record_outcomes ||=
      VaccinationRecord
        .kept
        .where(
          patient_id: patient_sessions.select(:patient_id),
          session_id: patient_sessions.select(:session_id)
        )
        .order(:patient_id, :session_id, :programme_id, created_at: :desc)
        .pluck(
          Arel.sql(
            "DISTINCT ON(patient_id, session_id, programme_id) patient_id, session_id, programme_id, outcome"
          )
        )
        .each_with_object({}) do |row, hash|
          hash[row.first] ||= {}
          hash[row.first][row.second] ||= {}
          hash[row.first][row.second][row.third] = row.last
        end
  end
end
