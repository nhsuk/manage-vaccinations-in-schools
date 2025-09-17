# frozen_string_literal: true

class AppTriageTableComponent < ViewComponent::Base
  def initialize(patient:, session:, programme:)
    @patient = patient
    @session = session
    @programme = programme
  end

  def render? = triages.any?

  private

  attr_reader :patient, :session, :programme

  delegate :govuk_table, :triage_status_tag, to: :helpers
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
