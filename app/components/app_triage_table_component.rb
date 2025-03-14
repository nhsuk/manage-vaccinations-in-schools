# frozen_string_literal: true

class AppTriageTableComponent < ViewComponent::Base
  def initialize(patient_session:, programme:)
    super

    @patient_session = patient_session
    @programme = programme
  end

  def render?
    triages.any?
  end

  private

  attr_reader :patient_session, :programme

  delegate :patient, :session, to: :patient_session

  def triages
    @triages ||=
      patient.triage_outcome.all[programme].sort_by(&:created_at).reverse
  end
end
