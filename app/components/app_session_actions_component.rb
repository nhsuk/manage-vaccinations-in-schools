# frozen_string_literal: true

class AppSessionActionsComponent < ViewComponent::Base
  erb_template <<-ERB
    <h3 class="nhsuk-heading-s nhsuk-u-margin-bottom-2">Action required</h3>
    <%= govuk_summary_list(rows:) %>
  ERB

  def initialize(session, patient_sessions:)
    super

    @session = session
    @patient_sessions = patient_sessions
  end

  def render?
    rows.any?
  end

  private

  attr_reader :session, :patient_sessions

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
      session_consent_path(session, search_form: { consent_status: status })

    {
      key: {
        text: text
      },
      value: {
        text: I18n.t("children", count:)
      },
      actions: [{ text: "Review", href: }]
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
      actions: [{ text: "Review", href: }]
    }
  end

  def register_attendance_row
    return nil unless session.today?

    count = patient_sessions.count { it.register_outcome.unknown? }

    return nil if count.zero?

    href =
      session_register_path(
        session,
        search_form: {
          register_status: PatientSession::RegisterOutcome::UNKNOWN
        }
      )

    {
      key: {
        text: "Register attendance"
      },
      value: {
        text: I18n.t("children", count:)
      },
      actions: [{ text: "Review", href: }]
    }
  end

  def ready_for_vaccinator_row
    return nil unless session.today?

    counts_by_programme =
      session.programmes.index_with do |programme|
        patient_sessions.count { it.ready_for_vaccinator?(programme:) }
      end

    return nil if counts_by_programme.values.all?(&:zero?)

    texts =
      counts_by_programme.map do |programme, count|
        "#{I18n.t("children", count:)} for #{programme.name}"
      end

    href = session_record_path(session)

    {
      key: {
        text: "Ready for vaccinator"
      },
      value: {
        text: safe_join(texts, tag.br)
      },
      actions: [{ text: "Review", href: }]
    }
  end
end
