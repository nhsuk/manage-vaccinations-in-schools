# frozen_string_literal: true

class AppConsentStatusComponent < ViewComponent::Base
  def initialize(patient_session:, programme:)
    @patient_session = patient_session
    @programme = programme
  end

  def call
    if consent_status.given?
      icon_tick "Consent given", "aqua-green"
    elsif consent_status.refused?
      icon_cross "Consent refused", "red"
    elsif consent_status.conflicts?
      icon_cross "Conflicting consent", "dark-orange"
    end
  end

  private

  attr_reader :patient_session, :programme

  delegate :patient, to: :patient_session

  def consent_status
    @consent_status ||=
      patient.consent_statuses.find_or_initialize_by(programme:)
  end

  def icon_tick(content, color)
    template = <<-ERB
      <p class="app-status app-status--#{color}">
        <svg class="nhsuk-icon nhsuk-icon--tick" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="16" height="16" focusable="false" aria-hidden="true">
          <path d="M11.4 18.8a2 2 0 0 1-2.7.1h-.1L4 14.1a1.5 1.5 0 0 1 2.1-2L10 16l8.1-8.1a1.5 1.5 0 1 1 2.2 2l-8.9 9Z"/>
        </svg>
        #{content}
      </p>
    ERB
    template.html_safe
  end

  def icon_cross(content, color)
    template = <<-ERB
      <p class="app-status app-status--#{color}">
        <svg class="nhsuk-icon nhsuk-icon--cross" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="16" height="16" focusable="false" aria-hidden="true">
          <path d="M17 18.5c-.4 0-.8-.1-1.1-.4l-10-10c-.6-.6-.6-1.6 0-2.1.6-.6 1.5-.6 2.1 0l10 10c.6.6.6 1.5 0 2.1-.3.3-.6.4-1 .4z M7 18.5c-.4 0-.8-.1-1.1-.4-.6-.6-.6-1.5 0-2.1l10-10c.6-.6 1.5-.6 2.1 0 .6.6.6 1.5 0 2.1l-10 10c-.3.3-.6.4-1 .4z"/>
        </svg>
        #{content}
      </p>
    ERB
    template.html_safe
  end
end
