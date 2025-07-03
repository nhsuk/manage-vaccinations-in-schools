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

  def should_send_notification?(patient:, session:, programmes:)
    return false unless patient.send_notifications?
    academic_year = patient_session.academic_year

    suitable_programmes =
      programmes.select do |programme|
        patient.consent_status(programme:, academic_year:).no_response? &&
          patient.vaccination_status(programme:, academic_year:).none_yet?
      end

    # TODO: I think we can get rid of this check the .any? later should be enough
    return false if suitable_programmes.empty?

    suitable_programmes.any? do |programme|
      initial_request = initial_request(patient:, programme:)
      return false if initial_request.nil?

      date_to_send_reminder =
        earliest_date_to_send_reminder(
          patient:,
          session:,
          programme:,
          initial_request_date: initial_request.sent_at.to_date
        )
      next false if date_to_send_reminder.nil?

      Date.current >= date_to_send_reminder
    end
  end

  def initial_request(patient:, programme:)
    patient
      .consent_notifications
      .sort_by(&:sent_at)
      .find { it.request? && it.programmes.include?(programme) }
  end

  def earliest_date_to_send_reminder(
    patient:,
    session:,
    programme:,
    initial_request_date:
  )
    session_dates_after_request =
      session.dates.select { it > initial_request_date }

    date_index_to_send_reminder_for =
      patient
        .consent_notifications
        .select { it.reminder? && it.programmes.include?(programme) }
        .length

    if date_index_to_send_reminder_for >= session_dates_after_request.length
      return nil
    end

    date_to_send_reminder_for =
      session_dates_after_request[date_index_to_send_reminder_for]

    date_to_send_reminder_for - session.days_before_consent_reminders.days
  end
end
