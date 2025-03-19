# frozen_string_literal: true

class AppSessionDetailsSummaryComponent < ViewComponent::Base
  def initialize(session, patient_sessions:, outcomes:)
    super

    @session = session
    @patient_sessions = patient_sessions
    @outcomes = outcomes
  end

  def call
    govuk_summary_list(rows: [cohort_row, consent_refused_row, vaccinated_row])
  end

  private

  attr_reader :session, :patient_sessions, :outcomes

  def cohort_row
    count = patient_sessions.length
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
    status = Patient::ConsentOutcome::REFUSED
    count =
      patient_sessions.count do
        it.patient.consent_outcome.status.values_at(*it.programmes).any?(status)
      end
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
          patient_sessions.count do
            outcomes.session.vaccinated?(it, programme:)
          end

        "#{I18n.t("vaccinations_given", count:)} for #{programme.name}"
      end

    href =
      session_outcome_path(
        session,
        search_form: {
          session_status: SessionOutcome::VACCINATED
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
