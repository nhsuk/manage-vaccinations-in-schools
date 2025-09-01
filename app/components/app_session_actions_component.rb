# frozen_string_literal: true

class AppSessionActionsComponent < ViewComponent::Base
  erb_template <<-ERB
    <h4 class="nhsuk-heading-s nhsuk-u-margin-bottom-2">Action required</h4>
    <%= govuk_summary_list(rows:) %>
  ERB

  def initialize(session)
    @session = session
  end

  def render? = rows.any?

  private

  attr_reader :session

  delegate :academic_year, :programmes, to: :session

  def patient_sessions
    session
      .patient_sessions
      .joins(:patient, :session)
      .appear_in_programmes(programmes)
  end

  def rows
    @rows ||= [
      no_nhs_number_row,
      no_consent_response_row,
      conflicting_consent_row,
      triage_required_row,
      register_attendance_row,
      ready_for_vaccinator_row
    ].compact
  end

  def no_nhs_number_row
    count = patient_sessions.merge(Patient.without_nhs_number).count
    href = session_patients_path(session, missing_nhs_number: true)

    generate_row(:children_without_nhs_number, count:, href:)
  end

  def no_consent_response_row
    status = "no_response"
    count =
      patient_sessions.has_consent_status(status, programme: programmes).count
    href = session_consent_path(session, consent_statuses: [status])
    actions = [
      {
        text: "Send reminders",
        href: session_manage_consent_reminders_path(session)
      }
    ]
    generate_row(:children_with_no_consent_response, count:, href:, actions:)
  end

  def conflicting_consent_row
    status = "conflicts"
    count =
      patient_sessions.has_consent_status(status, programme: programmes).count
    href = session_consent_path(session, consent_statuses: [status])

    generate_row(:children_with_conflicting_consent_response, count:, href:)
  end

  def triage_required_row
    status = "required"
    count =
      patient_sessions.has_triage_status(status, programme: programmes).count
    href = session_triage_path(session, triage_status: status)

    generate_row(:children_requiring_triage, count:, href:)
  end

  def register_attendance_row
    return nil unless session.requires_registration? && session.today?

    status = "unknown"
    count = patient_sessions.has_registration_status(status).count
    href = session_register_path(session, register_status: status)

    generate_row(:children_to_register, count:, href:)
  end

  def ready_for_vaccinator_row
    return nil unless session.today?

    counts_by_programme =
      session.programmes.index_with do |programme|
        patient_sessions
          .has_registration_status(%w[attending completed])
          .includes(
            patient: %i[consent_statuses triage_statuses vaccination_statuses]
          )
          .count do |patient_session|
            patient_session.patient.consent_given_and_safe_to_vaccinate?(
              programme:,
              academic_year:
            )
          end
      end

    return nil if counts_by_programme.values.all?(&:zero?)

    texts =
      if counts_by_programme.values.all?(&:zero?)
        ["No children"]
      else
        counts_by_programme.map do |programme, count|
          text =
            I18n.t(
              :children_for_programme,
              count:,
              programme: programme.name_in_sentence
            )
          href =
            session_record_path(
              session,
              search_form: {
                programme_types: [programme.type]
              }
            )
          count.positive? ? helpers.link_to(text, href) : text
        end
      end

    actions =
      unless counts_by_programme.values.all?(&:zero?)
        [{ text: "Record", href: session_record_path(session) }]
      end

    {
      key: {
        text: "Ready for vaccinator"
      },
      value: {
        text: safe_join(texts, tag.br)
      },
      actions: actions
    }
  end

  def generate_row(key, count:, href: nil, actions: nil)
    return nil if count.zero?

    {
      key: {
        text: I18n.t(:title, scope: key)
      },
      value: {
        text:
          (href ? helpers.link_to(I18n.t(key, count:), href).html_safe : text)
      },
      actions:
    }
  end
end
