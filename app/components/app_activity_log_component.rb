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
      notify_events,
      session_events,
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

  def notify_events
    @patient_session.patient.notify_log_entries.map do
      {
        title: "#{_1.title} sent",
        time: _1.created_at,
        notes: @patient_session.patient.restricted? ? "" : _1.recipient
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
