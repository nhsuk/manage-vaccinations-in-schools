# frozen_string_literal: true

class AppPatientSearchFormComponent < ViewComponent::Base
  def initialize(
    form,
    url:,
    programmes: [],
    consent_statuses: [],
    registration_statuses: [],
    triage_statuses: [],
    vaccination_statuses: [],
    patient_specific_direction_statuses: [],
    vaccine_criterias: [],
    year_groups: [],
    heading_level: 3,
    show_aged_out_of_programmes: false,
    show_still_to_vaccinate: false,
    show_eligible_children: false
  )
    @form = form
    @url = url

    @programmes = programmes
    @consent_statuses = consent_statuses
    @registration_statuses = registration_statuses
    @triage_statuses = triage_statuses
    @vaccination_statuses = vaccination_statuses
    @patient_specific_direction_statuses = patient_specific_direction_statuses
    @vaccine_criterias = vaccine_criterias
    @year_groups = year_groups
    @heading_level = heading_level
    @show_aged_out_of_programmes = show_aged_out_of_programmes
    @show_still_to_vaccinate = show_still_to_vaccinate
    @show_eligible_children = show_eligible_children
  end

  private

  attr_reader :form,
              :url,
              :programmes,
              :consent_statuses,
              :registration_statuses,
              :triage_statuses,
              :vaccination_statuses,
              :patient_specific_direction_statuses,
              :vaccine_criterias,
              :year_groups,
              :heading_level,
              :show_aged_out_of_programmes,
              :show_still_to_vaccinate,
              :show_eligible_children

  delegate :format_year_group,
           :govuk_button_link_to,
           :govuk_details,
           :tallying_enabled?,
           to: :helpers

  def open_details?
    @form.date_of_birth_year.present? || @form.date_of_birth_month.present? ||
      @form.date_of_birth_day.present? || @form.missing_nhs_number ||
      @form.archived || @form.aged_out_of_programmes
  end

  def show_buttons_in_details?
    !(
      consent_statuses.any? || vaccination_statuses.any? ||
        registration_statuses.any? || triage_statuses.any? || year_groups.any?
    )
  end

  def clear_filters_path = "#{@url}?_clear=true"
end
