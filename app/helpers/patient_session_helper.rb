module PatientSessionHelper
  STATUS_COLOURS_AND_TEXT = {
    added_to_session: {
      colour: :yellow,
      text: "Get consent",
    },
    consent_given_triage_needed: {
      colour: :blue,
      text: "Triage",
    },
    consent_given_triage_not_needed: {
      colour: :purple,
      text: "Vaccinate",
    },
    consent_refused: {
      colour: :orange,
      text: "Check refusal",
    },
    triaged_do_not_vaccinate: {
      colour: :red,
      text: "Do not vaccinate",
    },
    triaged_kept_in_triage: {
      colour: :"aqua-green",
      text: "Triage started",
    },
    triaged_ready_to_vaccinate: {
      colour: :purple,
      text: "Vaccinate",
    },
    unable_to_vaccinate: {
      colour: :orange,
      text: "Unable to vaccinate",
    },
    vaccinated: {
      colour: :green,
      text: "Vaccinated",
    },
  }.with_indifferent_access.freeze

  def status_colour_for_state(state)
    STATUS_COLOURS_AND_TEXT[state][:colour]
  end

  def status_text_for_state(state)
    STATUS_COLOURS_AND_TEXT[state][:text]
  end
end
