# frozen_string_literal: true

class SendSchoolSessionRemindersJob < ApplicationJob
  queue_as :notifications

  def perform
    date = Date.tomorrow

    sessions =
      Session
        .includes(:programmes, :location_programme_year_groups)
        .has_date(date)
        .joins(:location)
        .merge(Location.school)

    sessions.find_each do |session|
      patients =
        session.patients.includes_statuses.where.not(
          SessionNotification
            .where(session:)
            .where(
              "session_notifications.patient_id = patient_locations.patient_id"
            )
            .where(session_date: date)
            .arel
            .exists
        )

      patients.find_each do |patient|
        next unless should_send_notification?(patient:, session:)

        SessionNotification.create_and_send!(
          patient:,
          session:,
          session_date: date,
          type: :school_reminder
        )
      end
    end
  end

  def should_send_notification?(patient:, session:)
    return false unless patient.send_notifications?(team: session.team)

    programmes = session.programmes_for(patient:)
    academic_year = session.academic_year

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
