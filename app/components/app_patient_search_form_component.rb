# frozen_string_literal: true

class AppPatientSearchFormComponent < ViewComponent::Base
  def initialize(
    form,
    url:,
    current_team:,
    programmes: [],
    consent_statuses: [],
    programme_statuses: [],
    patient_specific_direction_statuses: [],
    registration_statuses: [],
    triage_statuses: [],
    vaccination_statuses: [],
    year_groups: [],
    heading_level: 3,
    show_aged_out_of_programmes: false,
    show_eligible_children: false,
    show_vaccine_criteria: false
  )
    @form = form
    @url = url
    @current_team = current_team

    @programmes = programmes
    @consent_statuses = consent_statuses
    @patient_specific_direction_statuses = patient_specific_direction_statuses
    @programme_statuses = programme_statuses
    @registration_statuses = registration_statuses
    @triage_statuses = triage_statuses
    @vaccination_statuses = vaccination_statuses
    @year_groups = year_groups
    @heading_level = heading_level
    @show_aged_out_of_programmes = show_aged_out_of_programmes
    @show_eligible_children = show_eligible_children
    @show_vaccine_criteria = show_vaccine_criteria
  end

  private

  attr_reader :form,
              :url,
              :current_team,
              :programmes,
              :consent_statuses,
              :patient_specific_direction_statuses,
              :programme_statuses,
              :registration_statuses,
              :triage_statuses,
              :vaccination_statuses,
              :vaccine_criterias,
              :year_groups,
              :heading_level,
              :show_aged_out_of_programmes,
              :show_eligible_children,
              :show_vaccine_criteria

  delegate :format_year_group,
           :govuk_button_link_to,
           :govuk_details,
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

  def has_vaccine_criteria?
    programmes.any? { |programme| vaccine_criteria_for(programme:).present? }
  end

  def show_vaccine_criteria_headings?
    programmes.count { |programme| vaccine_criteria_for(programme:).present? } >
      1
  end

  def vaccine_criteria_for(programme:)
    if programme.flu?
      %w[flu_injection_without_gelatine flu_nasal flu_nasal_injection]
    elsif programme.mmr?
      %w[mmr_injection mmr_injection_without_gelatine]
    else
      []
    end
  end

  def clear_filters_path = "#{@url}?_clear=true"
end
