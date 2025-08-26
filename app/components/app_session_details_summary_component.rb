# frozen_string_literal: true

class AppSessionDetailsSummaryComponent < ViewComponent::Base
  def initialize(session)
    super

    @session = session
  end

  def call
    govuk_summary_list(rows: [cohort_row, consent_refused_row, vaccinated_row])
  end

  private

  attr_reader :session

  delegate :programmes, to: :session

  def patient_sessions
    session
      .patient_sessions
      .joins(:patient, :session)
      .appear_in_programmes(programmes)
  end

  def cohort_row
    count = patient_sessions.count

    { key: { text: "Cohort" }, value: { text: I18n.t("children", count:) } }
  end

  def consent_refused_row
    status = "refused"

    count =
      patient_sessions.has_consent_status(status, programme: programmes).count

    href = session_consent_path(session, consent_statuses: [status])

    {
      key: {
        text: "Consent refused"
      },
      value: {
        text: I18n.t("children", count:)
      },
      actions: [
        { text: "Review", visually_hidden_text: "consent refused", href: }
      ]
    }
  end

  def vaccinated_row
    counts = session.vaccination_records.administered.group(:programme_id).count

    texts =
      session.programmes.map do |programme|
        count = counts.fetch(programme.id, 0)
        "#{I18n.t("vaccinations_given", count:)} for #{programme.name_in_sentence}"
      end

    href = session_patients_path(session, vaccination_status: "vaccinated")

    {
      key: {
        text: "Vaccinated"
      },
      value: {
        text: safe_join(texts, tag.br)
      },
      actions: [{ text: "Review", visually_hidden_text: "vaccinated", href: }]
    }
  end
end
