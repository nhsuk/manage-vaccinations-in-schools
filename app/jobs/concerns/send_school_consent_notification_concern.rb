# frozen_string_literal: true

module SendSchoolConsentNotificationConcern
  extend ActiveSupport::Concern

  included { queue_as :notifications }

  def patient_programmes_eligible_for_notification(session:)
    return unless session.school? && session.open_for_consent?

    session
      .patient_locations
      .includes_programmes
      .includes(patient: %i[consent_notifications consents vaccination_records])
      .find_each do |patient_location|
        patient = patient_location.patient
        next unless patient.send_notifications?

        ProgrammeGrouper
          .call(session.programmes_for(patient:))
          .each_value do |programmes|
            programmes_that_need_response =
              get_programmes_that_need_consent(patient:, session:, programmes:)
            next if programmes_that_need_response.empty?

            yield patient, programmes_that_need_response
          end
      end
  end

  def get_programmes_that_need_consent(patient:, session:, programmes:)
    academic_year = session.academic_year

    programmes.select do |programme|
      patient.consent_status(programme:, academic_year:).no_response? &&
        patient.vaccination_status(programme:, academic_year:).none_yet?
    end
  end

  def reminder_notification_type(patient:, programmes:)
    sent_initial_reminder =
      programmes.all? do |programme|
        patient
          .consent_notifications
          .select { it.programmes.include?(programme) }
          .any?(&:initial_reminder?)
      end

    sent_initial_reminder ? :subsequent_reminder : :initial_reminder
  end
end
