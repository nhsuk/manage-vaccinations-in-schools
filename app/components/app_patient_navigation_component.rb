# frozen_string_literal: true

class AppPatientNavigationComponent < ViewComponent::Base
  def initialize(patient, programmes, active:)
    @patient = patient
    @programmes = programmes
    @active = active
  end

  def render? = helpers.policy(patient).log?

  def call
    render AppSecondaryNavigationComponent.new do |nav|
      nav.with_item(
        href: patient_path(patient),
        text: "Child record",
        selected: active == :show
      )
      @programmes.flat_map do |programme|
        nav.with_item(href: patient_path(@patient), text: programme.name)
      end
      nav.with_item(
        href: log_patient_path(patient),
        text: "Activity log",
        selected: active == :log
      )
    end
  end

  private

  attr_reader :patient, :active
end
