# frozen_string_literal: true

class AppSessionPatientTableComponent < ViewComponent::Base
  def initialize(
    patient_sessions,
    caption: nil,
    columns: %i[name year_group],
    consent_form: nil,
    params: {},
    programme: nil
  )
    super

    @patient_sessions =
      patient_sessions.group_by(&:patient_id).map { _2.max_by(&:created_at) }

    @session = patient_sessions.first&.session

    @caption = caption
    @columns = columns
    @consent_form = consent_form
    @params = params
    @programme = programme || @session&.programmes&.first
    @year_groups = @session&.year_groups || programme&.year_groups || []
  end

  private

  attr_reader :params, :programme, :year_groups

  def column_name(column)
    {
      action: "Action needed",
      dob: "Date of birth",
      name: "Full name",
      status: "Status",
      postcode: "Postcode",
      reason: "Reason for refusal",
      year_group: "Year group",
      attendance: "Today’s attendance"
    }.fetch(column)
  end

  def column_value(patient_session, column)
    patient = patient_session.patient

    case column
    when :action
      status = patient_session.status(programme:)
      t("patient_session_statuses.#{status}.text")
    when :status
      status = patient_session.status(programme:)
      t("patient_session_statuses.#{status}.banner_title")
    when :dob
      patient.date_of_birth.to_fs(:long)
    when :name
      name_cell(patient_session)
    when :year_group
      helpers.patient_year_group(patient)
    when :reason
      patient_session.consent.all[programme]
        .map { it.human_enum_name(:reason_for_refusal) }
        .uniq
        .join("<br />")
        .html_safe
    when :postcode
      patient.restricted? ? "" : patient.address_postcode
    when :attendance
      attendance_cell(patient_session)
    else
      raise ArgumentError, "Unknown column: #{column}"
    end
  end

  def name_cell(patient_session)
    patient = patient_session.patient

    safe_join(
      [
        patient_link(patient_session),
        (
          if patient.has_preferred_name?
            "<span class=\"nhsuk-u-font-size-16\">Known as: ".html_safe +
              patient.preferred_full_name + "</span>".html_safe
          end
        )
      ].compact,
      tag.br
    )
  end

  def patient_link(patient_session)
    patient = patient_session.patient
    session = patient_session.session
    programme = @programme || patient_session.programmes.first

    link_to(
      patient.full_name,
      session_patient_programme_path(session, patient, programme)
    )
  end

  def attendance_cell(patient_session)
    tag.div(
      safe_join(
        [attending_button(patient_session), absent_button(patient_session)]
      ),
      class: "app-button-group app-button-group--table"
    )
  end

  def attending_button(patient_session)
    govuk_button_to(
      "Attending",
      session_register_attendance_path(
        session_slug: params[:session_slug],
        tab: :unregistered,
        patient_id: patient_session.patient_id,
        state: :attending
      ),
      class: "app-button--secondary app-button--small"
    )
  end

  def absent_button(patient_session)
    govuk_button_to(
      "Absent",
      session_register_attendance_path(
        session_slug: params[:session_slug],
        tab: :unregistered,
        patient_id: patient_session.patient_id,
        state: :absent
      ),
      class: "app-button--secondary-warning app-button--small"
    )
  end

  def header_link(column)
    return column_name(column) if column == :attendance

    direction =
      if params[:sort] == column.to_s && params[:direction] == "asc"
        "desc"
      else
        "asc"
      end

    data = { turbo: "true", turbo_action: "replace" }

    filter_params = {
      direction:,
      name: params[:name],
      postcode: params[:postcode],
      sort: column,
      year_groups: params[:year_groups]
    }

    path = patients_programme_path(programme, **filter_params)

    link_to column_name(column), path, data:
  end

  def form_url
    patients_programme_path(programme)
  end

  def header_attributes(column)
    sort =
      if params[:sort] == column.to_s
        params[:direction] == "asc" ? "ascending" : "descending"
      else
        "none"
      end
    { html_attributes: { aria: { sort: } } }
  end

  def status_options
    PatientSessionStatusConcern
      .available_statuses
      .map { t("patient_session_statuses.#{_1}.banner_title") }
      .uniq
      .sort
  end
end
