class AppOutcomeTagComponent < ViewComponent::Base
  def initialize(outcome:)
    super

    @outcome = outcome
  end

  def css_classes
    base_classes = "app-outcome-tag nhsuk-tag"
    outcome_classes = {
      no_outcome: " nhsuk-tag--white",
      vaccinated: " nhsuk-tag--green",
      no_consent: " nhsuk-tag--red",
      could_not_vaccinate: " nhsuk-tag--orange"
    }

    base_classes +
      (outcome_classes[@outcome] || raise("Unknown outcome: #{@outcome}"))
  end

  def outcome_text
    outcome_texts = {
      no_outcome: "No outcome yet",
      vaccinated: "Vaccinated",
      no_consent: "No consent",
      could_not_vaccinate: "Could not vaccinate"
    }

    outcome_texts[@outcome] || raise("Unknown outcome: #{@outcome}")
  end

  def svg_icon
    unless @outcome == :vaccinated ||
             @outcome.in?(%i[no_consent could_not_vaccinate])
      return nil
    end

    @outcome == :vaccinated ? "tick" : "cross"
  end
end
