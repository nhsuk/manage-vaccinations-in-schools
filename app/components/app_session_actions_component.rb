# frozen_string_literal: true

class AppSessionActionsComponent < ViewComponent::Base
  erb_template <<-ERB
    <h3 class="nhsuk-heading-s nhsuk-u-margin-bottom-2">Action required</h3>
    <%= govuk_summary_list(rows:) %>
  ERB

  def initialize(session, patient_sessions:, outcomes:)
    super

    @session = session
    @patient_sessions = patient_sessions
    @outcomes = outcomes
  end

  def render?
    rows.any?
  end

  private

  attr_reader :session, :patient_sessions, :outcomes

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
    consent_row(
      text: "No consent response",
      status: ConsentOutcome::NO_RESPONSE
    )
  end

  def conflicting_consent_row
    consent_row(text: "Conflicting consent", status: ConsentOutcome::CONFLICTS)
  end

  def consent_row(text:, status:)
    count =
      patient_sessions.count do |patient_session|
        patient_session.programmes.any? do |programme|
          outcomes.consent.status(patient_session.patient, programme:) == status
        end
      end

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
    count =
      patient_sessions.count do |patient_session|
        patient_session.programmes.any? do |programme|
          outcomes.triage.required?(patient_session.patient, programme:)
        end
      end

    return nil if count.zero?

    href =
      session_triage_path(
        session,
        search_form: {
          triage_status: TriageOutcome::REQUIRED
        }
      )

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

    count = patient_sessions.count { outcomes.register.unknown?(it) }

    return nil if count.zero?

    href =
      session_register_path(
        session,
        search_form: {
          register_status: RegisterOutcome::UNKNOWN
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
        patient_sessions.count do
          it.ready_for_vaccinator?(outcomes:, programme:)
        end
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
