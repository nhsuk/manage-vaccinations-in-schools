# frozen_string_literal: true

class AppSessionTableComponent < ViewComponent::Base
  def initialize(
    sessions,
    description: "sessions",
    show_programmes: false,
    show_consent_period: false
  )
    super

    @sessions = sessions
    @description = description
    @show_programmes = show_programmes
    @show_consent_period = show_consent_period
  end

  private

  attr_reader :sessions, :show_programmes, :show_consent_period

  def heading
    pluralize(sessions.count, @description)
  end
end
