# frozen_string_literal: true

class AppTriageTableComponent < ViewComponent::Base
  def initialize(patient_session:, programme:)
    @patient_session = patient_session
    @programme = programme
  end

  def render? = triages.any?

  private

  attr_reader :patient_session, :programme

  delegate :patient, :session, to: :patient_session
  delegate :academic_year, to: :session

  def triages
    @triages ||=
      patient
        .triages
        .includes(:performed_by, :programme)
        .where(academic_year:, programme:)
        .order(created_at: :desc)
  end
end
