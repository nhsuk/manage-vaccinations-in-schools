# frozen_string_literal: true

module ConsentsHelper
  ConsentRefusalOption = Struct.new(:value, :label, :divider)

  def consent_refusal_reasons(consent)
    reasons = %w[
      already_vaccinated
      will_be_vaccinated_elsewhere
      medical_reasons
      personal_choice
      other
    ]

    if consent.vaccine_may_contain_gelatine?
      reasons.insert(0, "contains_gelatine")
    end

    reasons.map do |value|
      label = Consent.human_enum_name(:reason_for_refusal, value)
      ConsentRefusalOption.new(value:, label:, divider: value == "other")
    end
  end

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
        "aqua-green"
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

    # We can’t use the colour param as NHS.UK frontend uses different colour
    # names (aqua-green) than those supported by GOV.UK Frontend (turquoise)
    if consent.invalidated?
      safe_join(
        [
          govuk_tag(text: tag.s(text), classes: "nhsuk-tag--#{colour}"),
          vaccine_method,
          tag.span("Invalid", class: "nhsuk-u-secondary-text-color")
        ].compact
      )
    elsif consent.withdrawn?
      safe_join(
        [
          govuk_tag(text: tag.s(text), classes: "nhsuk-tag--#{colour}"),
          vaccine_method,
          tag.span("Withdrawn", class: "nhsuk-u-secondary-text-color")
        ].compact
      )
    else
      safe_join(
        [
          govuk_tag(text:, classes: "nhsuk-tag--#{colour}"),
          vaccine_method
        ].compact
      )
    end
  end
end
