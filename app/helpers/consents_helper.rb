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

    programme =
      if consent.respond_to?(:programme)
        consent.programme
      elsif consent.respond_to?(:programmes)
        consent.programmes.first
      end

    reasons.map do |value|
      label_key =
        if value == "contains_gelatine"
          if programme&.flu?
            "#{value}_flu"
          elsif programme&.mmr? && (variant_type = programme.variant_type)
            "#{value}_#{variant_type}"
          else
            value
          end
        else
          value
        end

      label = Consent.human_enum_name(:reason_for_refusal, label_key)

      ConsentRefusalOption.new(value:, label:, divider: value == "other")
    end
  end

  def consent_response_tag(consent)
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

    # We can’t use the colour param as NHS.UK frontend uses different colour
    # names (aqua-green) than those supported by GOV.UK Frontend (turquoise)
    if consent.invalidated? || consent.withdrawn?
      primary_tag =
        govuk_tag(text: tag.s(text), classes: "nhsuk-tag--#{colour}")

      secondary_text =
        tag.span(class: "nhsuk-u-secondary-text-colour") do
          safe_join(
            [
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
      govuk_tag(text:, classes: "nhsuk-tag--#{colour}")
    end
  end

  def consent_parent_name(consentable)
    consentable.parent_full_name.presence ||
      (consentable.respond_to?(:parent) ? consentable.parent&.full_name : nil)
  end

  def consent_parent_email(consentable)
    consentable.parent_email.presence ||
      (consentable.respond_to?(:parent) ? consentable.parent&.email : nil)
  end

  def consent_parent_phone(consentable)
    consentable.parent_phone.presence ||
      (consentable.respond_to?(:parent) ? consentable.parent&.phone : nil)
  end

  def consent_parent_phone_receive_updates(consentable)
    value = consentable.parent_phone_receive_updates
    if value.nil? && consentable.respond_to?(:parent)
      consentable.parent&.phone_receive_updates
    else
      value
    end
  end
end
