# frozen_string_literal: true

class AppActivityLogComponent < ViewComponent::Base
  def initialize(patient_session)
    super

    @patient_session = patient_session
  end

  def events_by_day
    all_events.sort_by { -_1[:time].to_i }.group_by { _1[:time].to_date }
  end

  def all_events
    [
      consent_events,
      consent_notification_events,
      session_events,
      session_notification_events,
      triage_events,
      vaccination_events
    ].flatten
  end

  def consent_events
    @patient_session.patient.consents.recorded.map do
      {
        title: "Consent #{_1.response} by #{_1.name} (#{_1.who_responded})",
        time: _1.recorded_at
      }
    end
  end

  def consent_notification_events
    @patient_session.patient.consent_notifications.map do
      {
        title:
          if _1.request?
            "Consent request sent for #{_1.programme.name}"
          else
            "Consent reminder sent for #{_1.programme.name}"
          end,
        time: _1.sent_at
      }
    end
  end

  def session_events
    [
      {
        title: "Added to session at #{@patient_session.location.name}",
        time: @patient_session.created_at
      }
    ]
  end

  def session_notification_events
    @patient_session.patient.session_notifications.map do |notification|
      title =
        if notification.school_reminder?
          "School session reminder sent"
        elsif notification.clinic_invitation?
          "Clinic invitation sent"
        end
      { title:, time: notification.sent_at }
    end
  end

  def triage_events
    @patient_session.triages.map do
      {
        title: "Triaged decision: #{_1.human_enum_name(:status)}",
        time: _1.created_at,
        notes: _1.notes,
        by: _1.performed_by.full_name
      }
    end
  end

  def vaccination_events
    @patient_session.vaccination_records.recorded.map do
      {
        title: "Vaccinated with #{helpers.vaccine_heading(_1.vaccine)}",
        time: _1.created_at,
        notes: _1.notes,
        by: _1.performed_by&.full_name
      }
    end
  end
end
