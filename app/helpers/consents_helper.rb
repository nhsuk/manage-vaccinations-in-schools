# frozen_string_literal: true

module ConsentsHelper
  def consent_status_tag(consent)
    text =
      if consent.withdrawn?
        Consent.human_enum_name(:response, :given)
      else
        consent.human_enum_name(:response)
      end

    colour =
      if consent.withdrawn? || consent.invalidated?
        "grey"
      elsif consent.response_given?
        "green"
      elsif consent.response_refused?
        "red"
      else
        "blue"
      end

    if consent.invalidated?
      safe_join(
        [
          govuk_tag(text: tag.s(text), colour:),
          tag.span("Invalid", class: "nhsuk-u-secondary-text-color")
        ]
      )
    elsif consent.withdrawn?
      safe_join(
        [
          govuk_tag(text: tag.s(text), colour:),
          tag.span("Withdrawn", class: "nhsuk-u-secondary-text-color")
        ]
      )
    else
      govuk_tag(text:, colour:)
    end
  end
end
