# frozen_string_literal: true

class AppPatientSearchResultCardComponent < ViewComponent::Base
  def initialize(
    patient,
    link_to:,
    programme: nil,
    show_parents: false,
    show_postcode: false,
    show_school: false,
    show_year_group: false
  )
    super

    @patient = patient
    @link_to = link_to
    @programme = programme

    @show_parents = show_parents
    @show_postcode = show_postcode
    @show_school = show_school
    @show_year_group = show_year_group
  end

  def call
    render AppCardComponent.new(link_to: @link_to, patient: true) do |card|
      card.with_heading { @patient.full_name_with_known_as }

      govuk_summary_list do |summary_list|
        summary_list.with_row do |row|
          row.with_key { "Date of birth" }
          row.with_value { helpers.patient_date_of_birth(@patient) }
        end
        if @show_year_group
          summary_list.with_row do |row|
            row.with_key { "Year group" }
            row.with_value { helpers.patient_year_group(@patient) }
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
        if @programme
          summary_list.with_row do |row|
            row.with_key { "Programme outcome" }
            row.with_value { programme_outcome_tag }
          end
        end
      end
    end
  end

  private

  def programme_outcome_tag
    status = @patient.vaccination_status(programme: @programme).status
    render AppProgrammeStatusTagsComponent.new(
             { @programme => { status: } },
             outcome: :programme
           )
  end
end
