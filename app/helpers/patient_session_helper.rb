module PatientSessionHelper
  STATUS_COLOURS_AND_TEXT = {
    added_to_session: {
      text: "Get consent",
      banner_title: "No-one responded to our requests for consent"
    },
    consent_given_triage_needed: {
      text: "Triage",
      banner_title: "Triage needed"
    },
    consent_given_triage_not_needed: {
      text: "Vaccinate"
    },
    consent_refused: {
      text: "Check refusal",
      banner_title: "Their %{who_responded} has refused to give consent"
    },
    consent_conflicts: {
      text: "Check conflicting consent"
    },
    delay_vaccination: {
      text: "Delay vaccination to a later date",
      banner_title: "Delay vaccination to a later date"
    },
    triaged_do_not_vaccinate: {
      text: "Do not vaccinate",
      banner_title: "Do not vaccinate"
    },
    triaged_kept_in_triage: {
      text: "Triage started",
      banner_title: "Triage started"
    },
    triaged_ready_to_vaccinate: {
      text: "Vaccinate"
    },
    unable_to_vaccinate: {
      text: "Unable to vaccinate",
      banner_title: "Could not vaccinate"
    },
    unable_to_vaccinate_not_assessed: {
      text: "Not vaccinated",
      banner_title: "Not vaccinated"
    },
    unable_to_vaccinate_not_gillick_competent: {
      text: "Not vaccinated",
      banner_title: "Not vaccinated"
    },
    vaccinated: {
      text: "Vaccinated",
      banner_title: "Vaccinated"
    }
  }.with_indifferent_access.freeze

  def status_text_for_state(state)
    STATUS_COLOURS_AND_TEXT[state][:text]
  end

  def banner_title_for_state(state, params = {})
    return unless STATUS_COLOURS_AND_TEXT[state].key? :banner_title
    STATUS_COLOURS_AND_TEXT[state][:banner_title] % params
  end
end
