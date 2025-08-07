# frozen_string_literal: true

class AppPatientSearchResultCardComponent < ViewComponent::Base
  def initialize(
    patient,
    link_to:,
    programme: nil,
    academic_year: nil,
    triage_status: nil,
    show_parents: false,
    show_postcode: false,
    show_school: false,
    show_year_group: false
  )
    super

    @patient = patient
    @link_to = link_to
    @programme = programme
    @academic_year = academic_year || AcademicYear.current
    @triage_status = triage_status

    @show_parents = show_parents
    @show_postcode = show_postcode
    @show_school = show_school
    @show_year_group = show_year_group
  end

  def call
    render AppCardComponent.new(
             link_to: @link_to,
             heading_level: 4,
             compact: true
           ) do |card|
      card.with_heading { @patient.full_name_with_known_as }

      govuk_summary_list do |summary_list|
        summary_list.with_row do |row|
          row.with_key { "Date of birth" }
          row.with_value { helpers.patient_date_of_birth(@patient) }
        end
        if @show_year_group
          summary_list.with_row do |row|
            row.with_key { "Year group" }
            row.with_value do
              helpers.patient_year_group(@patient, academic_year:)
            end
          end
        end
        if @show_postcode && !@patient.restricted?
          summary_list.with_row do |row|
            row.with_key { "Postcode" }
            row.with_value { @patient.address_postcode }
          end
        end
        if @show_school
          summary_list.with_row do |row|
            row.with_key { "School" }
            row.with_value { helpers.patient_school(@patient) }
          end
        end
        if @show_parents && @patient.parent_relationships.any?
          summary_list.with_row do |row|
            row.with_key { "Parents or guardians" }
            row.with_value { helpers.patient_parents(@patient) }
          end
        end
        if @programme && @academic_year
          summary_list.with_row do |row|
            row.with_key { "Consent status" }
            row.with_value { consent_status_tag }
          end
          if display_triage_status?
            summary_list.with_row do |row|
              row.with_key { "Triage status" }
              row.with_value { triage_status_tag }
            end
          end
          summary_list.with_row do |row|
            row.with_key { "Programme outcome" }
            row.with_value { programme_outcome_tag }
          end
        end
      end
    end
  end

  private

  attr_reader :academic_year

  def programme_outcome_tag
    render_status_tag(:vaccination, :programme)
  end

  def consent_status_tag
    render_status_tag(:consent, :consent)
  end

  def triage_status_tag
    render_status_tag(:triage, :triage)
  end

  def render_status_tag(status_type, outcome)
    status_model =
      @patient.public_send(
        "#{status_type}_status",
        programme: @programme,
        academic_year: @academic_year
      )

    status =
      if status_type == :triage && status_model.vaccine_method.present? &&
           @programme.has_multiple_vaccine_methods?
        "#{status_model.status}_#{status_model.vaccine_method}"
      else
        status_model.status
      end

    latest_session_status =
      if status_type == :vaccination &&
           status_model.latest_session_status != status
        status_model.latest_session_status
      end

    render AppProgrammeStatusTagsComponent.new(
             { @programme => { status:, latest_session_status: } },
             outcome:
           )
  end

  def display_triage_status?
    return true if @triage_status.present?

    @patient.triage_status(
      programme: @programme,
      academic_year: @academic_year
    ).required?
  end
end
