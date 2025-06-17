# frozen_string_literal: true

class AppTriageFormComponent < ViewComponent::Base
  def initialize(
    triage_form,
    url:,
    method: :post,
    heading: true,
    continue: false
  )
    super

    @triage_form = triage_form
    @url = url
    @method = method
    @heading = heading
    @continue = continue
  end

  private

  attr_reader :triage_form, :url, :method, :heading, :continue

  delegate :patient_session, :programme, to: :triage_form
  delegate :patient, :session, to: :patient_session

  def builder = GOVUKDesignSystemFormBuilder::FormBuilder

  def fieldset_options
    text = "Is it safe to vaccinate #{patient.given_name}?"

    if heading
      { legend: { text:, tag: :h2 } }
    else
      { legend: { text:, size: "s", class: "app-fieldset__legend--reset" } }
    end
  end
end
