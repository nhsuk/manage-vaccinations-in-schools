# frozen_string_literal: true

class AppPatientSessionSearchResultCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <%= render AppCardComponent.new(heading_level: 4, compact: true) do |card| %>
      <% card.with_heading { link_to(patient.full_name_with_known_as, patient_path) } %>

      <%= govuk_summary_list do |summary_list|
            summary_list.with_row do |row|
              row.with_key { "Date of birth" }
              row.with_value { patient_date_of_birth(patient) }
            end

            summary_list.with_row do |row|
              row.with_key { "Year group" }
              row.with_value { patient_year_group(patient, academic_year:) }
            end

            if action_required
              summary_list.with_row do |row|
                row.with_key { "Action required" }
                row.with_value { action_required }
              end
            end
            
            if vaccination_method
              summary_list.with_row do |row|
                row.with_key { "Vaccination method" }
                row.with_value { vaccination_method }
              end
            end

            status_tags.each do |status_tag|
              summary_list.with_row do |row|
                row.with_key { I18n.t(status_tag[:key], scope: %i[status label]) }
                row.with_value { status_tag[:value] }
              end
            end

            if context != :patient_specific_direction && (note = patient_session.latest_note)
              summary_list.with_row do |row|
                row.with_key { "Notes" }
                row.with_value { render note_to_log_event(note) }
              end
            end
          end %>

      <% if context == :register && can_register_attendance? %>
        <div class="nhsuk-button-group">
          <%= govuk_button_to "Attending", create_session_register_path(session, patient, "present"), secondary: true, class: "app-button--small" %>
          <%= govuk_button_to "Absent", create_session_register_path(session, patient, "absent"), class: "app-button--secondary-warning app-button--small" %>
        </div>
      <% end %>
    <% end %>
  ERB

  def initialize(patient_session, context:, programmes: [])
    unless context.in?(
             %i[
               patients
               consent
               triage
               register
               record
               patient_specific_direction
             ]
           )
      raise "Unknown context: #{context}"
    end

    @patient_session = patient_session
    @patient = patient_session.patient
    @session = patient_session.session

    @context = context

    @programmes =
      if programmes.present?
        patient_session.programmes.select { it.in?(programmes) }
      else
        patient_session.programmes
      end
  end

  private

  attr_reader :patient_session, :patient, :session, :context, :programmes

  delegate :govuk_button_to,
           :govuk_summary_list,
           :patient_date_of_birth,
           :patient_year_group,
           :policy,
           to: :helpers
  delegate :academic_year, to: :session

  def can_register_attendance?
    session_attendance =
      SessionAttendance.new(
        patient_session:,
        session_date: SessionDate.new(value: Date.current)
      )

    policy(session_attendance).new?
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

        "#{I18n.t(status, scope: :activity)} for #{programme.name_in_sentence}"
      end

    return if next_activities.empty?

    tag.ul(class: "nhsuk-list nhsuk-list--bullet") do
      safe_join(next_activities.map { tag.li(it) })
    end
  end

  def vaccination_method
    return unless %i[register record].include?(context)

    programmes_to_check = programmes.select(&:has_multiple_vaccine_methods?)

    return if programmes_to_check.empty?

    vaccine_methods =
      programmes_to_check.flat_map do |programme|
        if patient.consent_given_and_safe_to_vaccinate?(
             programme:,
             academic_year:
           )
          patient.approved_vaccine_methods(programme:, academic_year:)
        else
          []
        end
      end

    return if vaccine_methods.empty?

    tag.span(
      class: "app-vaccine-method",
      data: {
        method: vaccine_methods.first
      }
    ) { Vaccine.human_enum_name(:method, vaccine_methods.first) }
  end

  def status_tags
    case context
    when :record
      []
    when :register
      [register_status_tag, vaccination_status_tag]
    when :consent
      [consent_status_tag]
    when :triage
      [triage_status_tag]
    when :patient_specific_direction
      [patient_specific_direction_status_tag]
    else
      [vaccination_status_tag]
    end
  end

  def consent_status_tag
    {
      key: :consent,
      value:
        render(
          AppProgrammeStatusTagsComponent.new(
            programmes.index_with do |programme|
              patient.consent_status(programme:, academic_year:).slice(
                :status,
                :vaccine_methods
              )
            end,
            outcome: :consent
          )
        )
    }
  end

  def vaccination_status_tag
    {
      key: :vaccination,
      value:
        render(
          AppProgrammeStatusTagsComponent.new(
            programmes.index_with do |programme|
              patient.vaccination_status(programme:, academic_year:).slice(
                :status,
                :latest_session_status
              )
            end,
            outcome: :programme
          )
        )
    }
  end

  def register_status_tag
    {
      key: :register,
      value:
        render(
          AppStatusTagComponent.new(
            patient_session.registration_status&.status || "unknown",
            context: :register
          )
        )
    }
  end

  def triage_status_tag
    {
      key: :triage,
      value:
        render(
          AppProgrammeStatusTagsComponent.new(
            programmes.index_with do |programme|
              triage_status_value(
                patient.triage_status(programme:, academic_year:),
                programme
              )
            end,
            outcome: :triage
          )
        )
    }
  end

  def triage_status_value(triage_status, programme)
    status =
      if triage_status.vaccine_method.present? &&
           programme.has_multiple_vaccine_methods?
        triage_status.status + "_#{triage_status.vaccine_method}"
      else
        triage_status.status
      end

    { status: status }
  end

  def patient_specific_direction_status_tag
    {
      key: :patient_specific_direction,
      value:
        render(
          AppStatusTagComponent.new(
            psd_exists?(programmes.first) ? :added : :not_added,
            context: :patient_specific_direction
          )
        )
    }
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

  def psd_exists?(programme)
    patient.patient_specific_directions.any? do
      it.programme_id == programme.id && it.academic_year == academic_year
    end
  end
end
