# frozen_string_literal: true

class SchoolConsentRemindersJob < ApplicationJob
  queue_as :notifications

  def perform
    sessions =
      Session
        .send_consent_reminders
        .includes(
          :programmes,
          patient_sessions: {
            patient: %i[consents consent_notifications parents]
          }
        )
        .preload(:session_dates)
        .eager_load(:location)
        .merge(Location.school)

    sessions.each do |session|
      next unless session.open_for_consent?

      session.patient_sessions.each do |patient_session|
        ProgrammeGrouper
          .call(patient_session.programmes)
          .each_value do |programmes|
            next unless should_send_notification?(patient_session:, programmes:)

            patient = patient_session.patient

            sent_initial_reminder =
              programmes.all? do |programme|
                patient
                  .consent_notifications
                  .select { it.programmes.include?(programme) }
                  .any?(&:initial_reminder?)
              end

            ConsentNotification.create_and_send!(
              patient:,
              programmes:,
              session:,
              type:
                sent_initial_reminder ? :subsequent_reminder : :initial_reminder
            )
          end
      end
    end
  end

  def should_send_notification?(patient_session:, programmes:)
    return false unless patient_session.send_notifications?

    has_consent_or_vaccinated =
      programmes.all? do |programme|
        patient_session.consent_outcome.all[programme].any? ||
          patient_session.programme_outcome.all[programme].any?
      end

    return false if has_consent_or_vaccinated

    patient = patient_session.patient
    session = patient_session.session

    programmes.any? do |programme|
      no_requests =
        patient.consent_notifications.none? do
          it.request? && it.programmes.include?(programme)
        end

      next false if no_requests

      date_index_to_send_reminder_for =
        patient
          .consent_notifications
          .select { it.reminder? && it.programmes.include?(programme) }
          .length

      next false if date_index_to_send_reminder_for >= session.dates.length

      date_to_send_reminder_for = session.dates[date_index_to_send_reminder_for]
      earliest_date_to_send_reminder =
        date_to_send_reminder_for - session.days_before_consent_reminders.days

      Date.current >= earliest_date_to_send_reminder
    end
  end
end
