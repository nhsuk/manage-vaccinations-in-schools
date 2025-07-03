# frozen_string_literal: true

class SendManualSchoolConsentRemindersJob < SendSchoolConsentRemindersJob
  attr_writer :current_user
  def current_user
    @current_user.presence ||
      raise("current_user must be set before sending manual reminders")
  end

  def perform(session, current_user:)
    self.current_user = current_user

    super(session)
  end

  def should_send_notification?(patient:, session:, programmes:)
    return false unless patient.send_notifications?
    academic_year = session.academic_year

    suitable_programmes =
      programmes.select do |programme|
        patient.consent_status(programme:, academic_year:).no_response? &&
          patient.vaccination_status(programme:, academic_year:).none_yet?
      end

    !suitable_programmes.empty?
  end
end
