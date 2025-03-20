# frozen_string_literal: true

class SchoolSessionRemindersJob < ApplicationJob
  queue_as :notifications

  def perform
    date = Date.tomorrow

    patient_sessions =
      PatientSession
        .includes(
          :gillick_assessments,
          patient: [:parents, { consents: %i[parent patient] }],
          session: :programmes
        )
        .eager_load(:session)
        .joins(:location)
        .merge(Location.school)
        .merge(Session.has_date(date))
        .notification_not_sent(date)

    outcomes = Outcomes.new(patient_sessions:)

    patient_sessions.each do |patient_session|
      next unless should_send_notification?(patient_session:, outcomes:)

      SessionNotification.create_and_send!(
        patient_session:,
        session_date: date,
        type: :school_reminder
      )
    end
  end

  def should_send_notification?(patient_session:, outcomes:)
    patient = patient_session.patient

    return false unless patient.send_notifications?

    programmes = patient_session.programmes

    all_vaccinated =
      programmes.all? do |programme|
        outcomes.programme.vaccinated?(patient, programme:)
      end

    return false if all_vaccinated

    programmes.any? do |programme|
      patient.consent_given_and_safe_to_vaccinate?(outcomes:, programme:)
    end
  end
end
