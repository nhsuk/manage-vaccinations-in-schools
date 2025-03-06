# frozen_string_literal: true

class AppSessionActionsSummaryComponent < ViewComponent::Base
  def initialize(session, patient_sessions:)
    super

    @session = session
    @patient_sessions = patient_sessions
  end

  def call
    govuk_summary_list(rows:)
  end

  private

  attr_reader :session, :patient_sessions

  def rows
    [get_consent_row, resolve_consent_row, triage_row, register_row].compact
  end

  def get_consent_row
    count =
      patient_sessions.count do
        it.consent.status.values.include?(PatientSession::Consent::NONE)
      end

    href =
      session_consent_path(
        session,
        search_form: {
          consent_status: PatientSession::Consent::NONE
        }
      )

    {
      key: {
        text: "Get consent"
      },
      value: {
        text: "#{I18n.t("children", count:)} without a response"
      },
      actions: [{ text: "Review", href: }]
    }
  end

  def resolve_consent_row
    count =
      patient_sessions.count do
        it.consent.status.values.include?(PatientSession::Consent::CONFLICTS)
      end

    href =
      session_consent_path(
        session,
        search_form: {
          consent_status: PatientSession::Consent::CONFLICTS
        }
      )

    {
      key: {
        text: "Resolve consent"
      },
      value: {
        text: "#{I18n.t("children", count:)} with conflicting consent"
      },
      actions: [{ text: "Review", href: }]
    }
  end

  def triage_row
    count =
      patient_sessions.count do
        it.triage.status.values.include?(PatientSession::Triage::REQUIRED)
      end

    href =
      session_triage_path(
        session,
        search_form: {
          triage_status: PatientSession::Triage::REQUIRED
        }
      )

    {
      key: {
        text: "Triage"
      },
      value: {
        text: I18n.t("children", count:)
      },
      actions: [{ text: "Review", href: }]
    }
  end

  def register_row
    return nil unless session.today?

    count =
      patient_sessions.count do
        it.register.unknown? && it.ready_for_vaccinator?
      end

    href =
      session_register_path(
        session,
        search_form: {
          register_status: PatientSession::Register::UNKNOWN
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
end
