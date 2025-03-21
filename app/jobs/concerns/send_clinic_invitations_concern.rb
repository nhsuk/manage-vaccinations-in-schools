# frozen_string_literal: true

module SendClinicInvitationsConcern
  extend ActiveSupport::Concern

  def send_notification(patient_session:, session_date:)
    type =
      if patient_session.session_notifications.any?
        :clinic_subsequent_invitation
      else
        :clinic_initial_invitation
      end

    SessionNotification.create_and_send!(patient_session:, session_date:, type:)
  end

  def should_send_notification?(patient_session:, programmes:, session_date:)
    patient = patient_session.patient

    return false unless patient.send_notifications?

    eligible_programmes = patient_session.programmes & programmes

    return false if eligible_programmes.empty?

    all_vaccinated =
      eligible_programmes.all? do |programme|
        patient.programme_outcome.vaccinated?(programme)
      end

    return false if all_vaccinated

    already_sent_notification =
      patient_session.session_notifications.any? do
        _1.session_date == session_date
      end

    return false if already_sent_notification

    all_consent_refused =
      eligible_programmes.all? do |programme|
        patient.consent_status(programme:).refused?
      end

    return false if all_consent_refused

    true
  end

  class InvalidLocation < StandardError
  end

  class NoSessionDates < StandardError
  end
end
