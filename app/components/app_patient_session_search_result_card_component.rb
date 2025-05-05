# frozen_string_literal: true

class AppPatientSessionSearchResultCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new(patient: true) do |card| %>
      <% card.with_heading { link_to(patient.full_name_with_known_as, patient_path) } %>

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
                row.with_key { I18n.t(status_tag[:key], scope: %i[status label]) }
                row.with_value { status_tag[:value] }
              end
            end

            if (note = patient_session.latest_note)
              summary_list.with_row do |row|
                row.with_key { "Notes" }
                row.with_value { render note_to_log_event(note) }
              end
            end
          end %>

      <% if context == :register && can_register_attendance? %>
        <div class="app-button-group">
          <%= helpers.govuk_button_to "Attending", create_session_register_path(session, patient, "present", search_form: params[:search_form]&.permit!), secondary: true, class: "app-button--small" %>
          <%= helpers.govuk_button_to "Absent", create_session_register_path(session, patient, "absent", search_form: params[:search_form]&.permit!), class: "app-button--secondary-warning app-button--small" %>
        </div>
      <% end %>
    <% end %>
  ERB

  def initialize(patient_session, context:, programmes: [])
    super

    unless context.in?(%i[consent triage register record outcome])
      raise "Unknown context: #{context}"
    end

    @patient_session = patient_session
    @patient = patient_session.patient
    @session = patient_session.session

    @context = context

    @programmes =
      programmes
        .select { it.year_groups.include?(patient.year_group) }
        .presence || patient_session.programmes
  end

  private

  attr_reader :patient_session, :patient, :session, :context, :programmes

  def can_register_attendance?
    session_attendance =
      SessionAttendance.new(
        patient_session:,
        session_date: SessionDate.new(value: Date.current)
      )
    helpers.policy(session_attendance).new?
  end

  def patient_path
    session_patient_programme_path(
      session,
      patient,
      programmes.first,
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
      {
        key: :register,
        value:
          render(
            AppRegisterStatusTagComponent.new(
              patient_session.registration_status&.status || "unknown"
            )
          )
      }
    when :consent
      {
        key: :consent,
        value:
          render(
            AppProgrammeStatusTagsComponent.new(
              programmes.index_with do |programme|
                patient.consent_status(programme:).slice(
                  :status,
                  :vaccine_methods
                )
              end,
              outcome: :consent
            )
          )
      }
    when :triage
      {
        key: :triage,
        value:
          render(
            AppProgrammeStatusTagsComponent.new(
              programmes.index_with do |programme|
                patient.triage_status(programme:).slice(:status)
              end,
              outcome: :triage
            )
          )
      }
    else
      {
        key: :session,
        value:
          render(
            AppProgrammeStatusTagsComponent.new(
              programmes.index_with do |programme|
                patient_session.session_status(programme:).slice(:status)
              end,
              outcome: :session
            )
          )
      }
    end
  end

  def note_to_log_event(note)
    truncated_body = note.body.truncate_words(80, omission: "…")

    continue_reading =
      if truncated_body.include?("…")
        tag.p(class: "nhsuk-u-margin-bottom-0") do
          link_to(session_patient_activity_path(session, patient)) do
            tag.span("Continue reading") +
              tag.span(
                "note for #{patient.full_name}",
                class: "nhsuk-u-visually-hidden"
              )
          end
        end
      end

    body = safe_join([truncated_body, continue_reading])

    AppLogEventComponent.new(body:, at: note.created_at, by: note.created_by)
  end
end
