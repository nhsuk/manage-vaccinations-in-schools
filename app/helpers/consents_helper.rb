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

    vaccine_method =
      if consent.vaccine_methods.present? &&
           consent.programme.has_multiple_vaccine_methods?
        tag.span(
          Vaccine.human_enum_name(:method, consent.vaccine_methods.first),
          class: "nhsuk-u-secondary-text-color"
        )
      end

    if consent.invalidated?
      safe_join(
        [
          govuk_tag(text: tag.s(text), colour:),
          vaccine_method,
          tag.span("Invalid", class: "nhsuk-u-secondary-text-color")
        ].compact
      )
    elsif consent.withdrawn?
      safe_join(
        [
          govuk_tag(text: tag.s(text), colour:),
          vaccine_method,
          tag.span("Withdrawn", class: "nhsuk-u-secondary-text-color")
        ].compact
      )
    else
      safe_join([govuk_tag(text:, colour:), vaccine_method].compact)
    end
  end
end
