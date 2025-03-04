# frozen_string_literal: true

class AppPatientSearchResultCardComponent < ViewComponent::Base
  def initialize(patient, link_to:)
    super

    @patient = patient
    @link_to = link_to
  end

  def call
    render AppCardComponent.new(link_to: @link_to, patient: true) do |card|
      card.with_heading { @patient.full_name_with_known_as }

      govuk_summary_list do |summary_list|
        summary_list.with_row do |row|
          row.with_key { "Date of birth" }
          row.with_value { helpers.patient_date_of_birth(@patient) }
        end
        unless @patient.restricted?
          summary_list.with_row do |row|
            row.with_key { "Postcode" }
            row.with_value { @patient.address_postcode }
          end
        end
        summary_list.with_row do |row|
          row.with_key { "School" }
          row.with_value { helpers.patient_school(@patient) }
        end
        if @patient.parent_relationships.any?
          summary_list.with_row do |row|
            row.with_key { "Parents or guardians" }
            row.with_value { helpers.patient_parents(@patient) }
          end
        end
      end
    end
  end
end
