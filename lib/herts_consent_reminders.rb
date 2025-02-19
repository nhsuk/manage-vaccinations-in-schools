# frozen_string_literal: true

# Use this module to send out additional consent reminders for Hertfordshire's
# sessions. The schedule is hardcoded into this module, which can be changed
# later. Use this module like so:
#
#   organisation = Organisation.find_by(ods_code: "RY4")
#   session = organisation.sessions.find(___)
#   HertsConsentReminders.send_consent_reminders(session)
#
# `filter_patients_to_send_consents` can also be used to test which patients
# will be sent notifications.

module HertsConsentReminders
  REMINDERS_BEFORE_SESSION_DAYS = [14, 7, 3].freeze

  def self.send_consent_reminders(session)
    return unless session.open_for_consent?

    filter_patients_to_send_consent(session).each do |patient, programme, type|
      ConsentNotification.create_and_send!(
        patient:,
        programme:,
        session:,
        type:
      )
    end
  end

  def self.filter_patients_to_send_consent(session)
    session.programmes.flat_map do |programme|
      session
        .patients
        .includes(:consents, :consent_notifications)
        .map do |patient|
          next unless should_send_notification?(patient:, programme:, session:)

          sent_initial_reminder =
            patient.consent_notifications.any?(&:initial_reminder?)

          [
            patient,
            programme,
            sent_initial_reminder ? :subsequent_reminder : :initial_reminder
          ]
        end
        .compact
    end
  end

  def self.should_send_notification?(patient:, programme:, session:)
    return false unless patient.send_notifications?

    return false if patient.has_consent?(programme)

    return false if patient.consent_notifications.none?(&:request?)

    reminders_sent = patient.consent_notifications.select(&:reminder?).length

    return false if reminders_sent >= REMINDERS_BEFORE_SESSION_DAYS.count

    session_date = session.dates.first
    reminder_dates = REMINDERS_BEFORE_SESSION_DAYS.map { session_date - it }
    next_reminder_date = reminder_dates[reminders_sent]

    Date.current >= next_reminder_date
  end
end
