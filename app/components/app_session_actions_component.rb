# frozen_string_literal: true

class AppSessionActionsComponent < ViewComponent::Base
  erb_template <<-ERB
    <h4 class="nhsuk-heading-s nhsuk-u-margin-bottom-2">Action required</h4>
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

  delegate :academic_year, :patient_sessions, :programmes, to: :session

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
    consent_row("No consent response", status: "no_response")
  end

  def conflicting_consent_row
    consent_row("Conflicting consent", status: "conflicts")
  end

  def consent_row(text, status:)
    count =
      patient_sessions.has_consent_status(status, programme: programmes).count

    return nil if count.zero?

    href =
      session_consent_path(session, search_form: { consent_statuses: [status] })

    {
      key: {
        text: text
      },
      value: {
        text: I18n.t("children", count:)
      },
      actions: [{ text: "Review", visually_hidden_text: text.downcase, href: }]
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
        text: I18n.t("children", count:)
      },
      actions: [
        { text: "Review", visually_hidden_text: "triage needed", href: }
      ]
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
        text: I18n.t("children", count:)
      },
      actions: [
        { text: "Review", visually_hidden_text: "register attendance", href: }
      ]
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
              programme:,
              academic_year:
            )
          end
      end

    return nil if counts_by_programme.values.all?(&:zero?)

    texts =
      counts_by_programme.map do |programme, count|
        "#{I18n.t("children", count:)} for #{programme.name_in_sentence}"
      end

    href = session_record_path(session)

    {
      key: {
        text: "Ready for vaccinator"
      },
      value: {
        text: safe_join(texts, tag.br)
      },
      actions: [
        { text: "Review", visually_hidden_text: "ready for vaccinator", href: }
      ]
    }
  end
end
