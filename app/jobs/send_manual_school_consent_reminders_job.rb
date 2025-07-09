# frozen_string_literal: true

class SendManualSchoolConsentRemindersJob < SendSchoolConsentRemindersJob
  attr_writer :current_user
  def current_user
    @current_user || nil
  end

  def perform(session, current_user:)
    self.current_user = current_user

    super(session)
  end

  def should_send_notification?(patient:, session:, programmes:)
    return false unless patient.send_notifications?

    has_consent_or_vaccinated =
      programmes.all? do |programme|
        patient.consents.any? { it.programme_id == programme.id } ||
          patient.vaccination_records.any? { it.programme_id == programme.id }
      end

    !has_consent_or_vaccinated
  end
end