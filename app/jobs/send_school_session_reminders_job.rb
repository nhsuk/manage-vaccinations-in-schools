# frozen_string_literal: true

class SendSchoolSessionRemindersJob < ApplicationJob
  queue_as :notifications

  def perform
    date = Date.tomorrow

    patient_sessions =
      PatientSession
        .includes_programmes
        .includes(patient: [:parents, { consents: %i[parent patient] }])
        .eager_load(:session)
        .joins(:location)
        .merge(Location.school)
        .merge(Session.has_date(date))
        .notification_not_sent(date)

    patient_sessions.find_each do |patient_session|
      next unless should_send_notification?(patient_session:)

      SessionNotification.create_and_send!(
        patient_session:,
        session_date: date,
        type: :school_reminder
      )
    end
  end

  def should_send_notification?(patient_session:)
    patient = patient_session.patient

    return false unless patient.send_notifications?

    session = patient_session.session
    programmes = session.programmes_for(patient:)
    academic_year = patient_session.academic_year

    all_vaccinated =
      programmes.all? do |programme|
        patient.vaccination_status(programme:, academic_year:).vaccinated?
      end

    return false if all_vaccinated

    programmes.any? do |programme|
      patient.consent_given_and_safe_to_vaccinate?(programme:, academic_year:)
    end
  end
end
