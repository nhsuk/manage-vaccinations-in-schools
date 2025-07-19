# frozen_string_literal: true

class SendSchoolConsentRequestsJob < ApplicationJob
  queue_as :notifications

  def perform(session)
    return unless session.school? && session.open_for_consent?

    session
      .patient_sessions
      .includes_programmes
      .includes(patient: %i[consent_notifications consents vaccination_records])
      .find_each do |patient_session|
        ProgrammeGrouper
          .call(patient_session.programmes)
          .each_value do |programmes|
            next unless should_send_notification?(patient_session:, programmes:)

            ConsentNotification.create_and_send!(
              patient: patient_session.patient,
              programmes:,
              session:,
              type: :request
            )
          end
      end
  end

  def should_send_notification?(patient_session:, programmes:)
    patient = patient_session.patient

    return false unless patient.send_notifications?

    academic_year = patient_session.academic_year

    suitable_programmes =
      programmes.select do |programme|
        patient.consent_status(programme:, academic_year:).no_response? &&
          patient.vaccination_status(programme:, academic_year:).none_yet?
      end

    return false if suitable_programmes.empty?

    suitable_programmes.any? do |programme|
      patient.consent_notifications.none? do
        it.request? && it.programmes.include?(programme)
      end
    end
  end
end
