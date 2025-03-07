# frozen_string_literal: true

class AppPatientSessionSearchResultCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new(link_to:, patient: true) do |card| %>
      <% card.with_heading { patient.full_name_with_known_as } %>

      <%= govuk_summary_list do |summary_list|
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
              row.with_value { status_tag }
            end
          end %>
      
      <% if context == :register %>
        <div class="app-button-group">
          <%= helpers.govuk_button_to "Attending", create_session_register_path(session, patient, "present", **params.permit(search_form: {})), class: "app-button--secondary app-button--small" %>
          <%= helpers.govuk_button_to "Absent", create_session_register_path(session, patient, "absent", **params.permit(search_form: {})), class: "app-button--secondary-warning app-button--small" %>
        </div>
      <% end %>
    <% end %>
  ERB

  def initialize(patient_session, context:)
    super

    @patient_session = patient_session
    @patient = patient_session.patient
    @session = patient_session.session
    @context = context

    unless context.in?(%i[consent triage register record outcome])
      raise "Unknown context: #{context}"
    end
  end

  private

  attr_reader :patient_session, :patient, :session, :context

  def link_to
    programme = patient_session.programmes.first
    session_patient_programme_path(
      session,
      patient,
      programme,
      return_to: context
    )
  end

  def status_tag
    if context == :register
      status = patient_session.register_outcome.status

      text = I18n.t(status, scope: %i[status register label])
      colour = I18n.t(status, scope: %i[status register colour])

      govuk_tag(text:, colour:)
    else
      outcome =
        case context
        when :consent
          patient.consent_outcome
        when :triage
          patient.triage_outcome
        when :record
          patient_session.session_outcome
        when :outcome
          patient.programme_outcome
        end

      # ensure status is calculated for each programme
      patient_session.programmes.each { outcome.status[it] }

      render AppProgrammeStatusTagsComponent.new(outcome.status, context:)
    end
  end
end
