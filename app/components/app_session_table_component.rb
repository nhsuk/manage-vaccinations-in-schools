# frozen_string_literal: true

class AppSessionTableComponent < ViewComponent::Base
  def initialize(
    sessions,
    heading: nil,
    show_dates: false,
    show_programmes: false,
    show_consent_period: false
  )
    super

    @sessions = sessions
    @heading = heading || pluralize(sessions.count, "session")
    @show_dates = show_dates
    @show_programmes = show_programmes
    @show_consent_period = show_consent_period
  end

  private

  attr_reader :sessions,
              :heading,
              :show_dates,
              :show_programmes,
              :show_consent_period

  def patient_count(session)
    patient_count_by_session_id.fetch(session.id, 0)
  end

  def patient_count_by_session_id
    @patient_count_by_session_id ||=
      PatientSession.where(session: sessions).group(:session_id).count
  end
end
