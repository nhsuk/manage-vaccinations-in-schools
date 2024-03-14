# frozen_string_literal: true

class AppConsentCardComponent < ViewComponent::Base
  def initialize(consent:, current_user:)
    super

    @consent = consent
    @current_user = current_user
  end

  def response_string
    {
      given: "Consent updated to given (by phone)",
      refused: "Refusal confirmed (by phone)",
      not_provided: "No response when contacted"
    }[
      @consent.response.to_sym
    ]
  end

  def heading
    by =
      {
        given: "Consent given by",
        refused: "Refusal confirmed by",
        not_provided: ""
      }[
        @consent.response.to_sym
      ]
    heading = "#{by} #{@consent.name.titleize}"
    heading += " (#{@consent.who_responded})" unless @consent.via_self_consent?
    heading
  end
end
