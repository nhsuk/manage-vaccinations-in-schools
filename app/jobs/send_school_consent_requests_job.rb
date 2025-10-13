# frozen_string_literal: true

class SendSchoolConsentRequestsJob < ApplicationJob
  include SendSchoolConsentNotificationConcern

  def perform(session)
    patients_and_programmes(session) do |patient, programmes|
      ConsentNotification.create_and_send!(
        patient:,
        session:,
        programmes:,
        type: :request,
        current_user: nil
      )
    end
  end

  def patients_and_programmes(session)
    patient_programmes_eligible_for_notification(
      session:
    ) do |patient, programmes|
      if should_send_notification?(patient:, programmes:)
        yield patient, programmes
      end
    end
  end

  def should_send_notification?(patient:, programmes:)
    programmes.any? do |programme|
      patient.consent_notifications.none? do
        it.request? && it.programmes.include?(programme)
      end
    end
  end
end
