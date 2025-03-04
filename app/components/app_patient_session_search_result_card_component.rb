# frozen_string_literal: true

class AppPatientSessionSearchResultCardComponent < ViewComponent::Base
  def initialize(patient_session, link_to:, context:)
    super

    @patient_session = patient_session
    @patient = patient_session.patient
    @link_to = link_to
    @context = context
  end

  def call
    render AppCardComponent.new(link_to:, patient: true) do |card|
      card.with_heading { patient.full_name_with_known_as }

      govuk_summary_list do |summary_list|
        summary_list.with_row do |row|
          row.with_key { "Date of birth" }
          row.with_value { helpers.patient_date_of_birth(patient) }
        end

        summary_list.with_row do |row|
          row.with_key { "Year group" }
          row.with_value { helpers.patient_year_group(patient) }
        end

        summary_list.with_row do |row|
          row.with_key { "Status" }
          row.with_value do
            render AppProgrammeStatusTagsComponent.new(
                     patient_session.consent.status,
                     context:
                   )
          end
        end
      end
    end
  end

  private

  attr_reader :patient_session, :patient, :link_to, :context
end
