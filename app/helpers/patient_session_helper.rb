module PatientSessionHelper
  STATUS_COLOURS_AND_TEXT = {
    added_to_session: {
      colour: "yellow",
      text: "Get consent",
      banner_title: "No-one responded to our requests for consent",
    },
    consent_given_triage_needed: {
      colour: "blue",
      text: "Triage",
      banner_title: "Triage needed",
    },
    consent_given_triage_not_needed: {
      colour: "purple",
      text: "Vaccinate",
    },
    consent_refused: {
      colour: "orange",
      text: "Check refusal",
      banner_title: "Their %{who_responded} has refused to give consent",
    },
    triaged_do_not_vaccinate: {
      colour: "red",
      text: "Do not vaccinate",
      banner_title: "Do not vaccinate",
    },
    triaged_kept_in_triage: {
      colour: "aqua-green",
      text: "Triage started",
      banner_title: "Triage started",
    },
    triaged_ready_to_vaccinate: {
      colour: "purple",
      text: "Vaccinate",
    },
    unable_to_vaccinate: {
      colour: "orange",
      text: "Unable to vaccinate",
      banner_title: "Could not vaccinate",
    },
    vaccinated: {
      colour: "green",
      text: "Vaccinated",
      banner_title: "Vaccinated",
    },
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
