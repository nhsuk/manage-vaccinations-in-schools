class AppStatusTagComponent < ViewComponent::Base
  def initialize(status:)
    super

    @status = status
  end

  def css_classes
    base_classes = "app-status-tag nhsuk-tag"
    status_classes = {
      no_outcome: " nhsuk-tag--white",
      vaccinated: " nhsuk-tag--green",
      no_consent: " nhsuk-tag--red",
      could_not_vaccinate: " nhsuk-tag--orange"
    }

    base_classes +
      (status_classes[@status] || raise("Unknown status: #{@status}"))
  end

  def status_text
    status_texts = {
      no_outcome: "No outcome yet",
      vaccinated: "Vaccinated",
      no_consent: "No consent",
      could_not_vaccinate: "Could not vaccinate"
    }

    status_texts[@status] || raise("Unknown status: #{@status}")
  end

  def svg_icon
    return nil unless @status.in?(%i[vaccinated no_consent could_not_vaccinate])

    @status == :vaccinated ? "tick" : "cross"
  end
end
