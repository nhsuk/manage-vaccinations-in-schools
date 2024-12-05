# frozen_string_literal: true

class AppTriageNotesComponent < ViewComponent::Base
  def initialize(patient_session:)
    super

    @patient_session = patient_session
  end

  def render?
    entries.present?
  end

  private

  def entries
    @entries ||=
      (triage_entries + pre_screening_entries).sort_by { -_1[:time].to_i }
  end

  def triage_entries
    @patient_session.triages.map do |triage|
      {
        title: "Triaged decision: #{triage.human_enum_name(:status)}",
        notes: triage.notes,
        time: triage.created_at,
        by: triage.performed_by.full_name,
        invalidated: triage.invalidated?
      }
    end
  end

  def pre_screening_entries
    @patient_session
      .pre_screenings
      .where.not(notes: "")
      .map do |pre_screening|
        {
          title: "Completed pre-screening checks",
          notes: pre_screening.notes,
          time: pre_screening.created_at,
          by: pre_screening.performed_by.full_name
        }
      end
  end
end
