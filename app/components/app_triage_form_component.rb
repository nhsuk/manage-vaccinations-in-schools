# frozen_string_literal: true

class AppTriageFormComponent < ViewComponent::Base
  def initialize(
    patient_session:,
    programme:,
    url:,
    method: :post,
    triage: nil,
    legend: nil
  )
    super

    @patient_session = patient_session
    @programme = programme
    @triage = triage || default_triage
    @url = url
    @method = method
    @legend = legend
  end

  private

  attr_reader :patient_session, :programme

  delegate :patient, to: :patient_session

  def fieldset_options
    text = "Is it safe to vaccinate #{@patient_session.patient.given_name}?"

    case @legend
    when :bold
      { legend: { text:, tag: :h2 } }
    when :hidden
      { legend: { text:, hidden: true } }
    else
      { legend: { text:, size: "s", class: "app-fieldset__legend--reset" } }
    end
  end

  def default_triage
    previous_triage =
      patient
        .triages
        .not_invalidated
        .order(created_at: :desc)
        .find_by(programme:)

    Triage.new(status: previous_triage&.status)
  end
end
