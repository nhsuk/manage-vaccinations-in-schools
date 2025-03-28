# frozen_string_literal: true

class AppProgrammeSessionTableComponent < ViewComponent::Base
  def initialize(sessions, programme:)
    super

    @sessions = sessions
    @programme = programme
  end

  private

  attr_reader :sessions, :programme

  def cohort_count(session:)
    format_number(session.patient_sessions.count)
  end

  def number_stat(session:)
    format_number(session.patient_sessions.select { yield it }.length)
  end

  def percentage_stat(session:)
    format_percentage(
      session.patient_sessions.select { yield it }.length,
      session.patient_sessions.count
    )
  end

  def no_response_scope(session:)
    session.patient_sessions.has_consent_status(:no_response, programme:)
  end

  def no_response_count(session:)
    format_number(no_response_scope(session:).count)
  end

  def no_response_percentage(session:)
    format_percentage(
      no_response_scope(session:).count,
      session.patient_sessions.count
    )
  end

  def triage_needed_count(session:)
    number_stat(session:) { it.patient.triage_outcome.required?(programme) }
  end

  def vaccinated_count(session:)
    number_stat(session:) { it.session_outcome.vaccinated?(programme) }
  end

  def vaccinated_percentage(session:)
    percentage_stat(session:) { it.session_outcome.vaccinated?(programme) }
  end

  def format_number(count) = count.to_s

  def format_percentage(count, total_count)
    return nil if total_count.zero?

    number_to_percentage(count / total_count.to_f * 100.0, precision: 0)
  end
end
