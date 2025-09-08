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
        Vaccine.human_enum_name(:method, consent.vaccine_methods.first)
      end

    # We can’t use the colour param as NHS.UK frontend uses different colour
    # names (aqua-green) than those supported by GOV.UK Frontend (turquoise)
    if consent.invalidated? || consent.withdrawn?
      primary_tag =
        govuk_tag(text: tag.s(text), classes: "nhsuk-tag--#{colour}")

      secondary_text =
        tag.span(class: "nhsuk-u-secondary-text-colour") do
          safe_join(
            [
              (tag.s(vaccine_method) if vaccine_method),
              if consent.invalidated?
                tag.span("Invalid")
              else
                tag.span("Withdrawn")
              end
            ].compact,
            " "
          )
        end

      safe_join([primary_tag, secondary_text])
    else
      primary_tag = govuk_tag(text:, classes: "nhsuk-tag--#{colour}")
      secondary_text =
        if vaccine_method
          tag.span(vaccine_method, class: "nhsuk-u-secondary-text-colour")
        end

      safe_join([primary_tag, secondary_text].compact)
    end
  end
end
