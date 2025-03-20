# frozen_string_literal: true

class AppProgrammeSessionTableComponent < ViewComponent::Base
  def initialize(sessions, programme:)
    super

    @sessions = sessions
    @programme = programme

    @patient_sessions =
      PatientSession
        .where(session: sessions)
        .eager_load(:patient)
        .preload(session: :programmes)
        .group_by(&:session_id)

    @outcomes =
      Outcomes.new(patient_sessions: PatientSession.where(session: sessions))
  end

  private

  attr_reader :sessions, :programme, :patient_sessions, :outcomes

  def cohort_count(session:)
    patient_sessions.fetch(session.id, []).length
  end

  def number_stat(session:)
    patient_sessions.fetch(session.id, []).select { yield it }.length.to_s
  end

  def percentage_stat(session:)
    total_count = patient_sessions.fetch(session.id, []).length
    return nil if total_count.zero?

    count = patient_sessions.fetch(session.id, []).select { yield it }.length

    number_to_percentage(count / total_count.to_f * 100.0, precision: 0)
  end

  def no_response_count(session:)
    number_stat(session:) do
      outcomes.consent.no_response?(it.patient, programme:)
    end
  end

  def no_response_percentage(session:)
    percentage_stat(session:) do
      outcomes.consent.no_response?(it.patient, programme:)
    end
  end

  def triage_needed_count(session:)
    number_stat(session:) { outcomes.triage.required?(it.patient, programme:) }
  end

  def vaccinated_count(session:)
    number_stat(session:) { outcomes.session.vaccinated?(it, programme:) }
  end

  def vaccinated_percentage(session:)
    percentage_stat(session:) { outcomes.session.vaccinated?(it, programme:) }
  end
end
