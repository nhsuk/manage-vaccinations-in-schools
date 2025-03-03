# frozen_string_literal: true

class AppProgrammeSessionTableComponent < ViewComponent::Base
  def initialize(sessions, programme:)
    super

    @sessions = sessions

    @stats =
      sessions.index_with do |session|
        PatientSessionStats.new(
          session.patient_sessions,
          keys: %i[without_a_response needing_triage vaccinated]
        ).fetch(programme)
      end
  end

  private

  attr_reader :sessions

  def cohort_count(session:)
    session.patient_sessions.length.to_s
  end

  def number_stat(session:, key:)
    @stats.dig(session, key).to_s
  end

  def percentage_stat(session:, key:)
    count = session.patient_sessions.length
    return nil if count.zero?

    value = @stats.dig(session, key) / count.to_f * 100.0
    number_to_percentage(value, precision: 0)
  end

  def no_response_count(session:)
    number_stat(session:, key: :without_a_response)
  end

  def no_response_percentage(session:)
    percentage_stat(session:, key: :without_a_response)
  end

  def triage_needed_count(session:)
    number_stat(session:, key: :needing_triage)
  end

  def vaccinated_count(session:)
    number_stat(session:, key: :vaccinated)
  end

  def vaccinated_percentage(session:)
    percentage_stat(session:, key: :vaccinated)
  end
end
