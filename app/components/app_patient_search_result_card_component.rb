# frozen_string_literal: true

class AppPatientSearchResultCardComponent < ViewComponent::Base
  def initialize(
    patient,
    link_to:,
    current_team:,
    programmes: [],
    academic_year: nil,
    show_nhs_number: false,
    show_parents: false,
    show_postcode: false,
    show_programme_status: true,
    show_school: false,
    show_year_group: false
  )
    @patient = patient
    @link_to = link_to
    @current_team = current_team

    @programmes = programmes
    @academic_year = academic_year || AcademicYear.pending

    @show_nhs_number = show_nhs_number
    @show_parents = show_parents
    @show_postcode = show_postcode
    @show_programme_status = show_programme_status
    @show_school = show_school
    @show_year_group = show_year_group
  end

  def call
    render AppCardComponent.new(link_to:, compact: true) do |card|
      card.with_heading(level: 4) { patient.full_name_with_known_as }

      govuk_summary_list(actions: false) do |summary_list|
        if show_nhs_number
          summary_list.with_row do |row|
            row.with_key { "NHS number" }
            row.with_value { patient_nhs_number(patient) }
          end
        end
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
        if show_programme_status && academic_year && programme_status_tag
          summary_list.with_row do |row|
            row.with_key { "Programme status" }
            row.with_value { programme_status_tag }
          end
        end
      end
    end
  end

  private

  attr_reader :patient,
              :link_to,
              :current_team,
              :programmes,
              :academic_year,
              :triage_status,
              :show_nhs_number,
              :show_parents,
              :show_postcode,
              :show_school,
              :show_year_group,
              :show_programme_status

  delegate :govuk_summary_list,
           :patient_date_of_birth,
           :patient_nhs_number,
           :patient_parents,
           :patient_school,
           :patient_year_group,
           to: :helpers

  def programme_status_tag
    return if programmes.empty?

    status_by_programme =
      programmes.each_with_object({}) do |programme, hash|
        resolved_status = status_resolver_for(programme).programme

        hash[resolved_status.fetch(:prefix)] = resolved_status
      end

    render AppAttachedTagsComponent.new(status_by_programme)
  end

  def status_resolver_for(programme)
    @status_resolver_for ||= {}
    @status_resolver_for[programme.type] ||= PatientStatusResolver.new(
      patient,
      programme:,
      academic_year:
    )
  end
end
