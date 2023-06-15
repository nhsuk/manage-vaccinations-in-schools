class AppStatusTagComponent < ViewComponent::Base
  def initialize(status:)
    super

    @status = status
  end

  def css_classes
    base_classes = "app-status-tag nhsuk-tag"
    status_classes = {
      :no_outcome => " nhsuk-tag--white",
      :vaccinated => " nhsuk-tag--green",
      :no_consent => " nhsuk-tag--red",
      :could_not_vaccinate => " nhsuk-tag--orange",
      "Do not vaccinate" => " nhsuk-tag--red",
      "Ready for session" => " nhsuk-tag--green",
      "Needs follow up" => " nhsuk-tag--blue",
      "To do" => " nhsuk-tag--grey",
      "No response" => " nhsuk-tag--white"
    }

    base_classes +
      (status_classes[@status] || raise("Unknown status: #{@status}"))
  end

  # Convert status symbols to text, if necessary
  def status_text
    status_texts = {
      no_outcome: "No outcome yet",
      vaccinated: "Vaccinated",
      no_consent: "No consent",
      could_not_vaccinate: "Could not vaccinate"
    }

    status_texts.fetch(@status, @status)
  end

  def svg_icon
    case @status
    when :vaccinated, "Ready for session"
      "tick"
    when :no_consent, :could_not_vaccinate, "Do not vaccinate"
      "cross"
    end
  end
end
