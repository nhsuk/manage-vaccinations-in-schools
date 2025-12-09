# frozen_string_literal: true

class DataMigration::CreateClinicNotifications
  def call
    clinic_notifications =
      session_notifications.map { build_clinic_notification(it) }

    ClinicNotification.import!(clinic_notifications)
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  def session_notifications
    SessionNotification.clinic_initial_invitation.or(
      SessionNotification.clinic_subsequent_invitation
    )
  end

  def build_clinic_notification(session_notification)
    return if session_notification.school_reminder?

    session = session_notification.session

    type =
      if session_notification.clinic_initial_invitation?
        :initial_invitation
      else
        :subsequent_invitation
      end

    ClinicNotification.new(
      academic_year: session.academic_year,
      programme_types: session.programme_types,
      sent_at: session_notification.sent_at,
      type:,
      patient_id: session_notification.patient_id,
      sent_by_user_id: session_notification.sent_by_user_id,
      team_id: session.team_id
    )
  end
end
