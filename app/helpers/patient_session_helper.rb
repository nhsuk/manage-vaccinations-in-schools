module PatientSessionHelper
  STATUS_COLOURS_AND_TEXT = {
    added_to_session: {
      text: "Get consent",
    },
    consent_given_triage_needed: {
      text: "Triage",
    },
    consent_given_triage_not_needed: {
      text: "Vaccinate"
    },
    consent_refused: {
      text: "Check refusal",
    },
    consent_conflicts: {
      text: "Check conflicting consent"
    },
    delay_vaccination: {
      text: "Delay vaccination to a later date",
    },
    triaged_do_not_vaccinate: {
      text: "Do not vaccinate",
    },
    triaged_kept_in_triage: {
      text: "Triage started",
    },
    triaged_ready_to_vaccinate: {
      text: "Vaccinate"
    },
    unable_to_vaccinate: {
      text: "Unable to vaccinate",
    },
    unable_to_vaccinate_not_assessed: {
      text: "Not vaccinated",
    },
    unable_to_vaccinate_not_gillick_competent: {
      text: "Not vaccinated",
    },
    vaccinated: {
      text: "Vaccinated",
    }
  }.with_indifferent_access.freeze

  def status_text_for_state(state)
    STATUS_COLOURS_AND_TEXT[state][:text]
  end
end
