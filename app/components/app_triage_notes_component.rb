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
    @entries ||= @patient_session.triage.order(created_at: :desc)
  end
end
