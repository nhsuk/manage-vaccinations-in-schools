# frozen_string_literal: true

class AppPatientSessionPsdSearchResultCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new(heading_level: 4, compact: true) do |card| %>
      <% card.with_heading { link_to(patient.full_name_with_known_as, patient_path) } %>

      <%= govuk_summary_list do |summary_list|
        summary_list.with_row do |row|
          row.with_key { "Date of birth" }
          row.with_value { helpers.patient_date_of_birth(patient) }
        end
  
        summary_list.with_row do |row|
          row.with_key { "Year group" }
          row.with_value { helpers.patient_year_group(patient, academic_year:) }
        end
        
        summary_list.with_row do |row|
          row.with_key { "PSD status" }
          row.with_value { psd_status_tag }
        end
      end %>
    <% end %>
  ERB

  def initialize(patient_session)
    super

    @patient_session = patient_session
    @patient = patient_session.patient
    @session = patient_session.session
    @programmes = patient_session.programmes
  end

  private

  attr_reader :patient_session, :patient, :session, :programmes

  delegate :academic_year, to: :session

  def patient_path
    session_patient_programme_path(
      session,
      patient,
      programmes.first,
      return_to: :patient_specific_directions
    )
  end

  def psd_status_tag
    status = psd_status_for_programme(programmes.first)
    text = t(status, scope: %i[status psd label])
    colour = t(status, scope: %i[status psd colour])

    tag.strong(text, class: ["nhsuk-tag nhsuk-tag--#{colour}"])
  end

  def psd_status_for_programme(programme)
    if patient
         .patient_specific_directions
         .where(programme:, academic_year:)
         .exists?
      :added
    else
      :not_added
    end
  end
end
