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
    @triage =
      triage ||
        Triage.new.tap do |t|
          if (latest_triage = patient_session.triage.latest(programme:))
            t.status = latest_triage.status
          end
        end
    @url = url
    @method = method
    @legend = legend
  end

  private

  attr_reader :programme

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
end
