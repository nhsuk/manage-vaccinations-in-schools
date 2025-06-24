# frozen_string_literal: true

class AppSessionActionsComponent < ViewComponent::Base
  erb_template <<-ERB
    <h3 class="nhsuk-heading-s nhsuk-u-margin-bottom-2">Action required</h3>
    <%= govuk_summary_list(rows:) %>
  ERB

  def initialize(session)
    super

    @session = session
  end

  def render?
    rows.any?
  end

  private

  attr_reader :session

  delegate :patient_sessions, to: :session

  delegate :programmes, to: :session

  def rows
    @rows ||= [
      no_consent_response_row,
      conflicting_consent_row,
      triage_required_row,
      register_attendance_row,
      ready_for_vaccinator_row
    ].compact
  end

  def no_consent_response_row
    status = "no_response"

    count =
      patient_sessions.has_consent_status(status, programme: programmes).count

    return nil if count.zero?

    href =
      session_consent_path(session, search_form: { consent_statuses: [status] })

    reminders_href = session_manage_consent_reminders_path(session)

    {
      key: {
        text: "No consent response"
      },
      value: {
        text:
          helpers.link_to(
            I18n.t(:children_with_no_consent_response, count:),
            href
          ).html_safe
      },
      actions: [{ text: "Send reminders", href: reminders_href }]
    }
  end

  def conflicting_consent_row
    status = "conflicts"

    count =
      patient_sessions.has_consent_status(status, programme: programmes).count

    return nil if count.zero?

    href =
      session_consent_path(session, search_form: { consent_statuses: [status] })

    {
      key: {
        text: "Conflicting consent"
      },
      value: {
        text:
          helpers.link_to(
            I18n.t(:children_with_conflicting_consent_response, count:),
            href
          ).html_safe
      }
    }
  end

  def triage_required_row
    status = "required"

    count =
      patient_sessions.has_triage_status(status, programme: programmes).count

    return nil if count.zero?

    href = session_triage_path(session, search_form: { triage_status: status })

    {
      key: {
        text: "Triage needed"
      },
      value: {
        text:
          helpers.link_to(
            I18n.t(:children_requiring_triage, count:),
            href
          ).html_safe
      }
    }
  end

  def register_attendance_row
    status = "unknown"

    count = patient_sessions.has_registration_status(status).count

    return nil if count.zero?

    href =
      session_register_path(session, search_form: { register_status: status })

    {
      key: {
        text: "Register attendance"
      },
      value: {
        text:
          helpers.link_to(I18n.t(:children_to_register, count:), href).html_safe
      }
    }
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
              programme:
            )
          end
      end

    texts =
      if counts_by_programme.values.all?(&:zero?)
        ["No children"]
      else
        counts_by_programme.map do |programme, count|
          text =
            I18n.t(:children_for_programme, count:, programme: programme.name)
          href =
            session_record_path(
              session,
              search_form: {
                programme_types: [programme.type]
              }
            )
          if count > 0
            helpers.link_to(text, href)
          else
            text
          end
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
end
