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

            if action_required
              summary_list.with_row do |row|
                row.with_key { "Action required" }
                row.with_value { action_required }
              end
            end

            if status_tag
              summary_list.with_row do |row|
                row.with_key { "Status" }
                row.with_value { status_tag }
              end
            end
          end %>

      <% if context == :register && can_register_attendance? %>
        <div class="app-button-group">
          <%= helpers.govuk_button_to "Attending", create_session_register_path(session, patient, "present", search_form: params[:search_form]&.permit!), class: "app-button--secondary app-button--small" %>
          <%= helpers.govuk_button_to "Absent", create_session_register_path(session, patient, "absent", search_form: params[:search_form]&.permit!), class: "app-button--secondary-warning app-button--small" %>
        </div>
      <% end %>
    <% end %>
  ERB

  def initialize(patient_session, context:)
    super

    unless context.in?(%i[consent triage register record outcome])
      raise "Unknown context: #{context}"
    end

    @patient_session = patient_session
    @context = context

    @patient = patient_session.patient
    @session = patient_session.session
  end

  private

  attr_reader :patient_session, :patient, :session, :context

  def can_register_attendance?
    session_attendance =
      SessionAttendance.new(
        patient_session:,
        session_date: SessionDate.new(value: Date.current)
      )
    helpers.policy(session_attendance).new?
  end

  def link_to
    programme = patient_session.programmes.first
    session_patient_programme_path(
      session,
      patient,
      programme,
      return_to: context
    )
  end

  def action_required
    return unless %i[register record].include?(context)

    next_activities =
      patient_session.programmes.filter_map do |programme|
        status = patient_session.next_activity(programme:)
        next if status.nil?

        "#{I18n.t(status, scope: :activity)} for #{programme.name}"
      end

    return if next_activities.empty?

    tag.ul(class: "nhsuk-list nhsuk-list--bullet") do
      safe_join(next_activities.map { tag.li(it) })
    end
  end

  def status_tag
    return if context == :record

    case context
    when :register
      render AppRegisterStatusTagComponent.new(
               patient_session.registration_status&.status || "unknown"
             )
    when :consent
      statuses =
        patient_session.programmes.index_with do |programme|
          patient.consent_status(programme:).status
        end
      render AppProgrammeStatusTagsComponent.new(statuses, outcome: :consent)
    when :triage
      statuses =
        patient_session.programmes.index_with do |programme|
          patient.triage_status(programme:).status
        end
      render AppProgrammeStatusTagsComponent.new(statuses, outcome: :triage)
    else
      statuses =
        patient_session.programmes.index_with do |programme|
          patient_session.session_status(programme:).status
        end
      render AppProgrammeStatusTagsComponent.new(statuses, outcome: :session)
    end
  end
end
