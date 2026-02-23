# frozen_string_literal: true

class AppPatientSecondaryNavigationComponent < ViewComponent::Base
  def initialize(patient:, current_user:, selected_tab: "child_record")
    @patient = patient
    @current_user = current_user
    @selected_tab = selected_tab
  end

  def render?
    helpers.policy(patient).log?
  end

  def call
    render AppSecondaryNavigationComponent.new do |nav|
      if Flipper.enabled?(:child_record_redesign)
        nav.with_item(
          href: patient_path(patient),
          text: "Child record",
          selected: selected_tab.to_s == "child_record"
        )
        current_user.programmes.flat_map do |programme|
          nav.with_item(
            href: patient_programme_path(patient, programme.type),
            text: programme.name,
            selected: programme.type == selected_tab
          )
        end
      else
        nav.with_item(
          href: patient_path(patient),
          text: "Child’s details",
          selected: selected_tab.to_s == "child_record"
        )
        nav.with_item(href: log_patient_path(patient), text: "Activity log")
      end
    end
  end

  private

  attr_reader :patient, :current_user, :selected_tab
end
