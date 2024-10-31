# frozen_string_literal: true

class AppActivityLogComponent < ViewComponent::Base
  def initialize(patient: nil, patient_session: nil)
    super

    if patient.nil? && patient_session.nil?
      raise "Pass either a patient or a patient session."
    elsif patient && patient_session
      raise "Pass only a patient or a patient session."
    end

    @patient = patient || patient_session.patient
    @patient_sessions =
      patient_session ? [patient_session] : patient.patient_sessions
    @consents = (patient || patient_session).consents
    @triages = (patient || patient_session).triages
    @vaccination_records = (patient || patient_session).vaccination_records
  end

  attr_reader :patient,
              :patient_sessions,
              :consents,
              :triages,
              :vaccination_records

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
    consents.recorded.map do
      {
        title: "Consent #{_1.response} by #{_1.name} (#{_1.who_responded})",
        time: _1.recorded_at
      }
    end
  end

  def notify_events
    patient.notify_log_entries.map do
      {
        title: "#{_1.title} sent",
        time: _1.created_at,
        notes: patient.restricted? ? "" : _1.recipient,
        by: _1.sent_by&.full_name
      }
    end
  end

  def session_events
    patient_sessions.map do |patient_session|
      [
        {
          title: "Added to session at #{patient_session.location.name}",
          time: patient_session.created_at
        }
      ]
    end
  end

  def triage_events
    triages.map do
      {
        title: "Triaged decision: #{_1.human_enum_name(:status)}",
        time: _1.created_at,
        notes: _1.notes,
        by: _1.performed_by.full_name
      }
    end
  end

  def vaccination_events
    vaccination_records.recorded.map do
      {
        title: "Vaccinated with #{helpers.vaccine_heading(_1.vaccine)}",
        time: _1.created_at,
        notes: _1.notes,
        by: _1.performed_by&.full_name
      }
    end
  end
end
