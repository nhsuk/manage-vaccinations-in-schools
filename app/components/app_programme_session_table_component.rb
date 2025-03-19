# frozen_string_literal: true

class AppProgrammeSessionTableComponent < ViewComponent::Base
  def initialize(sessions, programme:)
    super

    @sessions = sessions
    @programme = programme
    @outcomes =
      Outcomes.new(patient_sessions: PatientSession.where(session: sessions))
  end

  private

  attr_reader :sessions, :programme, :outcomes

  def cohort_count(session:)
    session.patient_sessions.length.to_s
  end

  def number_stat(session:)
    session.patient_sessions.select { yield it }.length.to_s
  end

  def percentage_stat(session:)
    total_count = session.patient_sessions.length
    return nil if total_count.zero?

    count = session.patient_sessions.select { yield it }.length

    number_to_percentage(count / total_count.to_f * 100.0, precision: 0)
  end

  def no_response_count(session:)
    number_stat(session:) { it.patient.consent_outcome.no_response?(programme) }
  end

  def no_response_percentage(session:)
    percentage_stat(session:) do
      it.patient.consent_outcome.no_response?(programme)
    end
  end

  def triage_needed_count(session:)
    number_stat(session:) { it.patient.triage_outcome.required?(programme) }
  end

  def vaccinated_count(session:)
    number_stat(session:) { outcomes.session.vaccinated?(it, programme:) }
  end

  def vaccinated_percentage(session:)
    percentage_stat(session:) { outcomes.session.vaccinated?(it, programme:) }
  end
end
