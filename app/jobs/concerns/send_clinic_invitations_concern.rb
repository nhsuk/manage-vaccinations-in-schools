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

    already_sent_notification =
      patient_session.session_notifications.any? do
        it.session_date == session_date
      end

    return false if already_sent_notification

    eligible_programmes = patient_session.programmes & programmes

    return false if eligible_programmes.empty?

    academic_year = session_date.academic_year

    eligible_programmes.any? do |programme|
      !patient.vaccination_status(programme:, academic_year:).vaccinated? &&
        !patient.consent_status(programme:, academic_year:).refused?
    end
  end

  class InvalidLocation < StandardError
  end

  class NoSessionDates < StandardError
  end
end
