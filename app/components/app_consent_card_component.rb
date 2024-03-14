# frozen_string_literal: true

class AppConsentCardComponent < ViewComponent::Base
  def initialize(consent:)
    super

    @consent = consent
  end

  def response_string
    {
      given: "Consent updated to given (by phone)",
      refused: "Refusal confirmed (by phone)",
      not_provided: "No response when contacted (by phone)"
    }[
      @consent.response.to_sym
    ]
  end

  def heading
    by =
      {
        given: "Consent given by",
        refused: "Refusal confirmed by",
        not_provided: "Contacted"
      }[
        @consent.response.to_sym
      ]
    heading = "#{by} #{@consent.name}"
    heading += " (#{@consent.who_responded})" unless @consent.via_self_consent?
    heading
  end
end
