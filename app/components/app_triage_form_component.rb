# frozen_string_literal: true

class AppTriageFormComponent < ViewComponent::Base
  def initialize(model:, url:, method: :post, heading: true, prefix: false)
    super

    @model = model
    @url = url
    @method = method
    @heading = heading
    @prefix = prefix
  end

  private

  attr_reader :model, :url, :method, :heading, :prefix

  delegate :patient, :programme, to: :model

  def builder = GOVUKDesignSystemFormBuilder::FormBuilder

  def fieldset_options
    text = "Is it safe to vaccinate #{patient.given_name}?"

    if heading
      { legend: { text:, tag: :h2 } }
    else
      { legend: { text:, size: "s", class: "app-fieldset__legend--reset" } }
    end
  end

  def status_field = prefix ? :triage_status : :status

  def notes_field = prefix ? :triage_notes : :notes
end
