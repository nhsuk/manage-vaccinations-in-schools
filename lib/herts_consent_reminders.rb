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

  def self.sessions_with_reminders_due(on_date: Date.current, ods_code: "RY4")
    reminder_dates = REMINDERS_BEFORE_SESSION_DAYS.map { on_date.to_date + it }

    Organisation
      .find_by(ods_code:)
      .sessions
      .includes(
        :programmes,
        patient_sessions: {
          patient: %i[consents consent_notifications parents]
        }
      )
      .joins(:session_dates)
      .eager_load(:location)
      .strict_loading(false)
      .where(session_dates: { value: reminder_dates })
      .select(&:open_for_consent?)
  end

  def self.send_consent_reminders(session, on_date: Date.current)
    return unless session.open_for_consent?

    filter_patients_to_send_consent(
      session,
      on_date: on_date.to_date
    ).each do |patient, programmes, type|
      ConsentNotification.create_and_send!(
        patient:,
        programmes:,
        session:,
        type:
      )
    end
  end

  def self.filter_patients_to_send_consent(session, on_date: Date.current)
    session
      .patient_sessions
      .flat_map do |patient_session|
        ProgrammeGrouper
          .call(patient_session.programmes)
          .map do |_type, programmes|
            unless should_send_notification?(
                     patient_session:,
                     programmes:,
                     on_date: on_date.to_date
                   )
              next
            end

            patient = patient_session.patient
            sent_initial_reminder =
              programmes.all? do |programme|
                patient
                  .consent_notifications
                  .select { it.programmes.include?(programme) }
                  .any?(&:initial_reminder?)
              end

            [
              patient,
              programmes,
              sent_initial_reminder ? :subsequent_reminder : :initial_reminder
            ]
          end
      end
      .compact
  end

  def self.should_send_notification?(
    patient_session:,
    programmes:,
    on_date: Date.current
  )
    return false unless patient_session.send_notifications?

    # return false if patient.has_consent?(programme)
    has_consent_or_vaccinated =
      programmes.all? do |programme|
        patient_session.consents(programme:).any? ||
          patient_session.vaccinated?(programme:) ||
          patient_session.unable_to_vaccinate?(programme:)
      end

    return false if has_consent_or_vaccinated

    patient = patient_session.patient
    session = patient_session.session

    programmes.any? do |programme|
      # return false if patient.consent_notifications.none?(&:request?)
      no_requests =
        patient.consent_notifications.none? do
          it.request? && it.programmes.include?(programme)
        end

      next false if no_requests

      last_sent =
        patient
          .consent_notifications
          .select { it.programmes.include?(programme) }
          .map(&:sent_at)
          .max
      next false if last_sent&.to_date == Date.current

      reminders_sent =
        patient
          .consent_notifications
          .select { it.reminder? && it.programmes.include?(programme) }
          .length
      next false if reminders_sent >= REMINDERS_BEFORE_SESSION_DAYS.count

      next_reminder_date = next_reminder_for_session(session, reminders_sent)
      on_date.to_date >= next_reminder_date
    end
  end

  def self.next_reminder_for_session(session, reminders_sent)
    session_date = session.dates.first
    reminder_dates = REMINDERS_BEFORE_SESSION_DAYS.map { session_date - it }
    reminder_dates[reminders_sent]
  end
end
