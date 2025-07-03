# frozen_string_literal: true

class SendSchoolConsentRemindersJob < ApplicationJob
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
              type: reminder_type(patient:, programmes:),
              current_user: current_user
            )
          end
      end
  end

  def reminder_type(patient:, programmes:)
    sent_initial_reminder =
      programmes.all? do |programme|
        patient
          .consent_notifications
          .select { it.programmes.include?(programme) }
          .any?(&:initial_reminder?)
      end

    sent_initial_reminder ? :subsequent_reminder : :initial_reminder
  end

  def current_user = nil

  def should_send_notification?(patient:, session:, programmes:)
    raise NotImplementedError, "This method should be implemented in a subclass"
  end
end
