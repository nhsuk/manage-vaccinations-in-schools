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
    format_number(
      session.patient_sessions.has_triage_status(:required, programme:).count
    )
  end

  def vaccinated_scope(session:)
    session.patient_sessions.has_session_status(:vaccinated, programme:)
  end

  def vaccinated_count(session:)
    format_number(vaccinated_scope(session:).count)
  end

  def vaccinated_percentage(session:)
    format_percentage(
      vaccinated_scope(session:).count,
      session.patient_sessions.count
    )
  end

  def format_number(count) = count.to_s

  def format_percentage(count, total_count)
    return nil if total_count.zero?

    number_to_percentage(count / total_count.to_f * 100.0, precision: 0)
  end
end
