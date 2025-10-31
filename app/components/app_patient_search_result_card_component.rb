# frozen_string_literal: true

class AppPatientSearchResultCardComponent < ViewComponent::Base
  def initialize(
    patient,
    link_to:,
    programmes: [],
    academic_year: nil,
    show_consent_status: false,
    show_nhs_number: false,
    show_parents: false,
    show_postcode: false,
    show_school: false,
    show_triage_status: false,
    show_year_group: false
  )
    @patient = patient
    @link_to = link_to
    @programmes = programmes
    @academic_year = academic_year || AcademicYear.pending

    @show_consent_status = show_consent_status
    @show_nhs_number = show_nhs_number
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
        if academic_year
          if show_consent_status && consent_status_tag
            summary_list.with_row do |row|
              row.with_key { "Consent status" }
              row.with_value { consent_status_tag }
            end
          end
          if show_triage_status && triage_status_tag
            summary_list.with_row do |row|
              row.with_key { "Triage status" }
              row.with_value { triage_status_tag }
            end
          end
          if vaccination_status_tag
            summary_list.with_row do |row|
              row.with_key { "Programme status" }
              row.with_value { vaccination_status_tag }
            end
          end
        end
      end
    end
  end

  private

  attr_reader :patient,
              :link_to,
              :programmes,
              :academic_year,
              :triage_status,
              :show_consent_status,
              :show_nhs_number,
              :show_parents,
              :show_postcode,
              :show_school,
              :show_triage_status,
              :show_year_group

  delegate :govuk_summary_list,
           :patient_date_of_birth,
           :patient_nhs_number,
           :patient_parents,
           :patient_school,
           :patient_year_group,
           to: :helpers

  def vaccination_status_tag = status_tag(:vaccination)

  def consent_status_tag = status_tag(:consent)

  def triage_status_tag = status_tag(:triage)

  def status_tag(type)
    @status_tag ||= {}
    @status_tag[type] ||= begin
      status_by_programme =
        programmes.each_with_object({}) do |programme, hash|
          if (status_hash = status_resolver_for(programme).send(type))
            hash[programme.name] = status_hash
          end
        end

      if status_by_programme.present?
        render AppAttachedTagsComponent.new(status_by_programme)
      end
    end
  end

  def status_resolver_for(programme)
    @status_resolver_for ||= {}
    @status_resolver_for[programme.id] ||= PatientStatusResolver.new(
      patient,
      programme:,
      academic_year:
    )
  end

  def patient_appears_in_programme?(programme)
    year_group = patient.year_group(academic_year:)

    patient.location_programme_year_groups.any? do
      it.academic_year == academic_year && it.year_group == year_group &&
        it.programme_id == programme.id
    end
  end
end
