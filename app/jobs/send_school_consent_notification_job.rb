# frozen_string_literal: true

class SendSchoolConsentNotificationJob < ApplicationJob
  queue_as :notifications

  def perform(session)
    return unless session.school? && session.open_for_consent?

    session
      .patient_sessions
      .includes_programmes
      .includes(patient: %i[consent_notifications consents vaccination_records])
      .find_each do |patient_session|
        patient = patient_session.patient
        session = patient_session.session
        ProgrammeGrouper
          .call(patient_session.programmes)
          .each_value do |programmes|
            unless should_send_notification?(patient:, session:, programmes:)
              next
            end

            ConsentNotification.create_and_send!(
              patient:,
              programmes:,
              session:,
              type: notification_type(patient:, programmes:),
              current_user: current_user
            )
          end
      end
  end

  def notification_type(patient:, programmes:)
    raise NotImplementedError, "This method should be implemented in a subclass"
  end

  def current_user = nil

  def should_send_notification?(patient:, session:, programmes:)
    raise NotImplementedError, "This method should be implemented in a subclass"
  end
end
