# frozen_string_literal: true

class AppPatientSessionSearchResultCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <% card_link = @context != :register ? patient_path : nil %>
    <%= render AppCardComponent.new(link_to: card_link, compact: true) do |card| %>
      <% if card_link.nil? %>
        <% card.with_heading(level: 4) { link_to(patient.full_name_with_known_as, patient_path) } %>
      <% else %>
        <% card.with_heading(level: 4) { patient.full_name_with_known_as } %>
      <% end %>

      <%= govuk_summary_list(actions: false) do |summary_list|
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
            
            if vaccine_type
              summary_list.with_row do |row|
                row.with_key { "Vaccine type" }
                row.with_value { vaccine_type }
              end
            end

            status_tags.each do |status_tag|
              summary_list.with_row do |row|
                row.with_key { I18n.t(status_tag[:key], scope: %i[status label]) }
                row.with_value { status_tag[:value] }
              end
            end

            if context != :patient_specific_direction && latest_note
              summary_list.with_row do |row|
                row.with_key { "Notes" }
                row.with_value { render note_to_log_event(latest_note) }
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

  def initialize(patient:, session:, context:, programmes: [])
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

    @patient = patient
    @session = session
    @context = context

    @programmes =
      if programmes.present?
        session.programmes_for(patient:).select { it.in?(programmes) }
      else
        session.programmes_for(patient:)
      end
  end

  private

  attr_reader :patient, :session, :context, :programmes

  delegate :govuk_button_to,
           :govuk_summary_list,
           :patient_date_of_birth,
           :patient_year_group,
           :policy,
           to: :helpers
  delegate :academic_year, to: :session

  def can_register_attendance?
    attendance_record =
      AttendanceRecord.new(
        patient:,
        location: session.location,
        date: Date.current
      )

    attendance_record.session = session

    policy(attendance_record).new?
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
      session
        .programmes_for(patient:)
        .filter_map do |programme|
          status = patient.next_activity(programme:, academic_year:)
          next if status.nil?

          "#{I18n.t(status, scope: :activity)} for #{programme.name_in_sentence}"
        end

    render_bullet_list_or_single(next_activities)
  end

  def vaccine_type
    return unless %i[register record].include?(context)

    programmes_to_check =
      programmes.select do
        it.has_multiple_vaccine_methods? || it.vaccine_may_contain_gelatine?
      end

    return if programmes_to_check.empty?

    labels =
      programmes_to_check.filter_map do |programme|
        if patient.consent_given_and_safe_to_vaccinate?(
             programme:,
             academic_year:
           )
          vaccine_criteria =
            patient.vaccine_criteria(programme:, academic_year:)

          render AppVaccineCriteriaLabelComponent.new(
                   vaccine_criteria,
                   programme:,
                   context: :vaccine_type
                 )
        end
      end

    render_bullet_list_or_single(labels)
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
      value: render(AppAttachedTagsComponent.new(attached_tags(:consent)))
    }
  end

  def vaccination_status_tag
    {
      key: :vaccination,
      value: render(AppAttachedTagsComponent.new(attached_tags(:vaccination)))
    }
  end

  def register_status_tag
    {
      key: :register,
      value:
        render(
          AppStatusTagComponent.new(
            patient.registration_status(session:)&.status || "unknown",
            context: :register
          )
        )
    }
  end

  def triage_status_tag
    {
      key: :triage,
      value: render(AppAttachedTagsComponent.new(attached_tags(:triage)))
    }
  end

  def patient_specific_direction_status_tag
    {
      key: :patient_specific_direction,
      value:
        render(
          AppStatusTagComponent.new(
            has_patient_specific_direction? ? :added : :not_added,
            context: :patient_specific_direction
          )
        )
    }
  end

  def attached_tags(context)
    programmes.each_with_object({}) do |programme, hash|
      hash[programme.name] = PatientStatusResolver.new(
        patient,
        programme:,
        academic_year:,
        context_location_id: session.location_id
      ).send(context)
    end
  end

  def latest_note
    patient
      .notes
      .sort_by(&:created_at)
      .reverse
      .find { it.session_id == session.id }
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

  def has_patient_specific_direction?
    programme_ids = programmes.map(&:id)
    patient.patient_specific_directions.any? do
      it.programme_id.in?(programme_ids) && it.academic_year == academic_year &&
        !it.invalidated?
    end
  end

  def render_bullet_list_or_single(items)
    return if items.empty?

    if items.size == 1
      items.first
    else
      tag.ul(class: "nhsuk-list nhsuk-list--bullet") do
        safe_join(items.map { tag.li(it) })
      end
    end
  end
end
