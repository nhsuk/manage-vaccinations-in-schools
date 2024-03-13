module PatientSessionHelper
  STATUS_COLOURS_AND_TEXT = {
    added_to_session: {
      colour: "blue",
      text: "Get consent",
      banner_title: "No-one responded to our requests for consent"
    },
    consent_given_triage_needed: {
      colour: "blue",
      text: "Triage",
      banner_title: "Triage needed"
    },
    consent_given_triage_not_needed: {
      colour: "purple",
      text: "Vaccinate"
    },
    consent_refused: {
      colour: "orange",
      text: "Check refusal",
      banner_title: "Their %{who_responded} has refused to give consent"
    },
    consent_conflicts: {
      colour: "orange",
      text: "Check conflicting consent"
    },
    delay_vaccination: {
      colour: "red",
      text: "Delay vaccination to a later date",
      banner_title: "Delay vaccination to a later date"
    },
    triaged_do_not_vaccinate: {
      colour: "red",
      text: "Do not vaccinate",
      banner_title: "Do not vaccinate"
    },
    triaged_kept_in_triage: {
      colour: "blue",
      text: "Triage started",
      banner_title: "Triage started"
    },
    triaged_ready_to_vaccinate: {
      colour: "purple",
      text: "Vaccinate"
    },
    unable_to_vaccinate: {
      colour: "red",
      text: "Unable to vaccinate",
      banner_title: "Could not vaccinate"
    },
    unable_to_vaccinate_not_assessed: {
      colour: "red",
      text: "Not vaccinated",
      banner_title: "Not vaccinated"
    },
    unable_to_vaccinate_not_gillick_competent: {
      colour: "red",
      text: "Not vaccinated",
      banner_title: "Not vaccinated"
    },
    vaccinated: {
      colour: "green",
      text: "Vaccinated",
      banner_title: "Vaccinated"
    }
  }.with_indifferent_access.freeze

  def status_colour_for_state(state)
    STATUS_COLOURS_AND_TEXT[state][:colour]
  end

  def status_text_for_state(state)
    STATUS_COLOURS_AND_TEXT[state][:text]
  end

  def banner_title_for_state(state, params = {})
    return unless STATUS_COLOURS_AND_TEXT[state].key? :banner_title
    STATUS_COLOURS_AND_TEXT[state][:banner_title] % params
  end
end
