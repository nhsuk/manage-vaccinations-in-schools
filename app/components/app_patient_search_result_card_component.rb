# frozen_string_literal: true

class AppPatientSearchResultCardComponent < ViewComponent::Base
  def initialize(
    patient,
    link_to:,
    programme: nil,
    academic_year: nil,
    show_parents: false,
    show_postcode: false,
    show_school: false,
    show_triage_status: false,
    show_year_group: false
  )
    @patient = patient
    @link_to = link_to
    @programme = programme
    @academic_year = academic_year || AcademicYear.pending

    @show_parents = show_parents
    @show_postcode = show_postcode
    @show_school = show_school
    @show_triage_status = show_triage_status
    @show_year_group = show_year_group
  end

  def call
    render AppCardComponent.new(link_to:, compact: true) do |card|
      card.with_heading(level: 4) { patient.full_name_with_known_as }

      govuk_summary_list do |summary_list|
        summary_list.with_row do |row|
          row.with_key { "Date of birth" }
          row.with_value { patient_date_of_birth(patient) }
        end
        if show_year_group
          summary_list.with_row do |row|
            row.with_key { "Year group" }
            row.with_value { patient_year_group(patient, academic_year:) }
          end
        end
        if show_postcode && !patient.restricted?
          summary_list.with_row do |row|
            row.with_key { "Postcode" }
            row.with_value { patient.address_postcode }
          end
        end
        if show_school
          summary_list.with_row do |row|
            row.with_key { "School" }
            row.with_value { patient_school(patient) }
          end
        end
        if show_parents && patient.parent_relationships.any?
          summary_list.with_row do |row|
            row.with_key { "Parents or guardians" }
            row.with_value { patient_parents(patient) }
          end
        end
        if programme && academic_year
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
            row.with_key { "Vaccination status" }
            row.with_value { vaccination_status_tag }
          end
        end
      end
    end
  end

  private

  attr_reader :patient,
              :link_to,
              :programme,
              :academic_year,
              :triage_status,
              :show_parents,
              :show_postcode,
              :show_school,
              :show_triage_status,
              :show_year_group

  delegate :govuk_summary_list,
           :patient_date_of_birth,
           :patient_parents,
           :patient_school,
           :patient_year_group,
           to: :helpers

  def vaccination_status_tag = status_tag(:vaccination)

  def consent_status_tag = status_tag(:consent)

  def triage_status_tag = status_tag(:triage)

  def status_tag(type)
    status_model =
      patient.public_send("#{type}_status", programme:, academic_year:)

    status =
      if type == :triage && status_model.vaccine_method.present? &&
           programme.has_multiple_vaccine_methods?
        "#{status_model.status}_#{status_model.vaccine_method}"
      else
        status_model.status
      end

    latest_session_status =
      (status_model.latest_session_status if type == :vaccination)

    render AppProgrammeStatusTagsComponent.new(
             { programme => { status:, latest_session_status: } },
             context: type
           )
  end

  def display_triage_status?
    show_triage_status ||
      patient.triage_status(programme:, academic_year:).required?
  end
end
