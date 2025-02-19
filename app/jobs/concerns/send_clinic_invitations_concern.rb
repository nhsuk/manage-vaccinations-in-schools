# frozen_string_literal: true

module SendClinicInvitationsConcern
  extend ActiveSupport::Concern

  def send_notification(patient_session:, programmes:, session_date:)
    unless should_send_notification?(
             patient_session:,
             programmes:,
             session_date:
           )
      return
    end

    type =
      if patient_session.session_notifications.any?
        :clinic_subsequent_invitation
      else
        :clinic_initial_invitation
      end

    SessionNotification.create_and_send!(patient_session:, session_date:, type:)
  end

  def should_send_notification?(patient_session:, programmes:, session_date:)
    return false unless patient_session.send_notifications?

    all_vaccinated =
      programmes.all? do |programme|
        patient_session.vaccination_administered?(programme:)
      end

    return false if all_vaccinated

    already_sent_notification =
      patient_session.session_notifications.any? do
        _1.session_date == session_date
      end

    return false if already_sent_notification

    all_consent_refused =
      programmes.all? do |programme|
        patient_session.consent_refused?(programme:)
      end

    return false if all_consent_refused

    true
  end

  class InvalidLocation < StandardError
  end

  class NoSessionDates < StandardError
  end
end
