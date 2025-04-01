# frozen_string_literal: true

class AppSessionDetailsSummaryComponent < ViewComponent::Base
  def initialize(session, patient_sessions:)
    super

    @session = session
    @patient_sessions = patient_sessions
  end

  def call
    govuk_summary_list(rows: [cohort_row, consent_refused_row, vaccinated_row])
  end

  private

  attr_reader :session, :patient_sessions

  delegate :programmes, to: :session

  def cohort_row
    count = patient_sessions.count
    href = new_draft_class_import_path(session)

    {
      key: {
        text: "Cohort"
      },
      value: {
        text: I18n.t("children", count:)
      },
      actions: [{ text: "Import class lists", href: }]
    }
  end

  def consent_refused_row
    status = "refused"

    count =
      patient_sessions.has_consent_status(status, programme: programmes).count

    href =
      session_consent_path(session, search_form: { consent_status: status })

    {
      key: {
        text: "Consent refused"
      },
      value: {
        text: I18n.t("children", count:)
      },
      actions: [{ text: "Review", href: }]
    }
  end

  def vaccinated_row
    texts =
      session.programmes.map do |programme|
        count =
          patient_sessions.has_session_status(:vaccinated, programme:).count

        "#{I18n.t("vaccinations_given", count:)} for #{programme.name}"
      end

    href =
      session_outcome_path(
        session,
        search_form: {
          session_status: "vaccinated"
        }
      )

    {
      key: {
        text: "Vaccinated"
      },
      value: {
        text: safe_join(texts, tag.br)
      },
      actions: [{ text: "Review", href: }]
    }
  end
end
