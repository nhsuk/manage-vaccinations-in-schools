# frozen_string_literal: true

class SchoolSessionRemindersJob < ApplicationJob
  queue_as :notifications

  def perform
    date = Date.tomorrow

    patient_sessions =
      PatientSession
        .includes(
          :gillick_assessments,
          patient: [
            :parents,
            :triages,
            :vaccination_records,
            { consents: %i[parent patient] }
          ],
          session: :programmes
        )
        .eager_load(:session)
        .joins(:location)
        .merge(Location.school)
        .merge(Session.has_date(date))
        .notification_not_sent(date)

    patient_sessions.each do |patient_session|
      next unless should_send_notification?(patient_session:)

      SessionNotification.create_and_send!(
        patient_session:,
        session_date: date,
        type: :school_reminder
      )
    end
  end

  def should_send_notification?(patient_session:)
    return false unless patient_session.send_notifications?

    programmes = patient_session.programmes

    all_vaccinated =
      programmes.all? do |programme|
        patient_session.vaccination_administered?(programme:)
      end

    return false if all_vaccinated

    patient_session.ready_for_vaccinator?
  end
end
