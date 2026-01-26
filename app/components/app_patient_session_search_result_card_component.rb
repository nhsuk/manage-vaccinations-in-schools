# frozen_string_literal: true

class AppPatientSessionSearchResultCardComponent < ViewComponent::Base
  erb_template <<-ERB
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

            if show_notes && latest_note
              summary_list.with_row do |row|
                row.with_key { "Notes" }
                row.with_value { note_blockquote(latest_note) }
              end
            end
          end %>

      <% if show_registration_status && can_register_attendance? %>
        <div class="nhsuk-button-group">
          <%= govuk_button_to "Attending", register_session_patients_path(session, patient, "present"), secondary: true, class: "nhsuk-button--small" %>
          <%= govuk_button_to "Absent", register_session_patients_path(session, patient, "absent"), class: "app-button--secondary-warning nhsuk-button--small" %>
        </div>
      <% end %>
    <% end %>
  ERB

  def initialize(
    patient:,
    session:,
    programmes: [],
    return_to: nil,
    show_notes: false,
    show_patient_specific_direction_status: false,
    show_programme_status: false,
    show_registration_status: false,
    show_vaccine_type: false
  )
    @patient = patient
    @session = session

    @programmes =
      if programmes.present?
        session.programmes_for(patient:).select { it.in?(programmes) }
      else
        session.programmes_for(patient:)
      end

    @return_to = return_to

    @show_notes = show_notes
    @show_patient_specific_direction_status =
      show_patient_specific_direction_status
    @show_programme_status = show_programme_status
    @show_registration_status = show_registration_status
    @show_vaccine_type = show_vaccine_type
  end

  private

  attr_reader :patient,
              :session,
              :programmes,
              :return_to,
              :show_notes,
              :show_patient_specific_direction_status,
              :show_programme_status,
              :show_registration_status,
              :show_vaccine_type

  delegate :govuk_button_to,
           :govuk_summary_list,
           :patient_date_of_birth,
           :patient_year_group,
           :policy,
           to: :helpers

  delegate :academic_year, :team, to: :session

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
      return_to:
    )
  end

  def card_link = show_registration_status ? nil : patient_path

  def vaccine_type
    return unless show_vaccine_type

    programmes_to_check =
      programmes.select do
        it.has_multiple_vaccine_methods? || it.vaccine_may_contain_gelatine?
      end

    return if programmes_to_check.empty?

    programmes_with_variants =
      programmes_to_check.map do |programme|
        disease_types =
          patient.programme_status(programme, academic_year:).disease_types

        programme.variant_for(disease_types:)
      end

    labels =
      programmes_with_variants.filter_map do |programme|
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
    [
      registration_status_tag,
      programme_status_tag,
      patient_specific_direction_status_tag
    ].compact
  end

  def programme_status_tag
    return unless show_programme_status

    status_by_programme =
      programmes.each_with_object({}) do |programme, hash|
        resolved_status =
          PatientProgrammeStatusResolver.call(
            patient,
            programme_type: programme.type,
            academic_year:,
            context_location_id: session.location_id
          )

        hash[resolved_status.fetch(:prefix)] = resolved_status
      end

    {
      key: :programme,
      value: render(AppAttachedTagsComponent.new(status_by_programme))
    }
  end

  def registration_status_tag
    return unless show_registration_status

    {
      key: :registration,
      value:
        render(
          AppStatusTagComponent.new(
            patient.registration_status(session:)&.status || "unknown",
            context: :registration
          )
        )
    }
  end

  def patient_specific_direction_status_tag
    return unless show_patient_specific_direction_status

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

  def latest_note
    patient
      .notes
      .sort_by(&:created_at)
      .reverse
      .find { it.session_id == session.id }
  end

  def note_blockquote(note)
    truncated_body = tag.p(note.body.truncate_words(80, omission: "…"))

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

    blockquote =
      tag.blockquote { safe_join([truncated_body, continue_reading]) }

    subtitle =
      tag.p(
        "#{note.created_by.full_name} &middot; #{note.created_at.to_fs(:long)}".html_safe,
        class: "nhsuk-body-s nhsuk-u-margin-0 nhsuk-u-secondary-text-colour"
      )

    safe_join([blockquote, subtitle])
  end

  def has_patient_specific_direction?
    programme_types = programmes.map(&:type)
    patient.patient_specific_directions.any? do
      it.programme_type.in?(programme_types) &&
        it.academic_year == academic_year && !it.invalidated?
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
