# frozen_string_literal: true

module TriagesHelper
  def triage_status_text(triage)
    return if triage.nil?

    if triage.delay_vaccination? && triage.delay_vaccination_until.present?
      "Delay vaccination until #{triage.delay_vaccination_until.to_fs(:long)}"
    else
      status_method =
        if triage.programme.has_multiple_vaccine_methods? &&
             triage.vaccine_method.present?
          triage.status + "_#{triage.vaccine_method}"
        else
          triage.status
        end

      Triage.human_enum_name(:status, status_method)
    end
  end

  def triage_status_tag(triage)
    text = triage_status_text(triage)

    colour =
      if triage.invalidated?
        "grey"
      elsif triage.safe_to_vaccinate?
        "aqua-green"
      elsif triage.do_not_vaccinate?
        "red"
      elsif triage.delay_vaccination?
        "dark-orange"
      else
        "blue"
      end

    # We can’t use the colour param as NHS.UK frontend uses different colour
    # names (aqua-green) than those supported by GOV.UK Frontend (turquoise)
    if triage.invalidated?
      safe_join(
        [
          govuk_tag(text: tag.s(text), classes: "nhsuk-tag--#{colour}"),
          tag.span("Invalid", class: "nhsuk-u-secondary-text-colour")
        ]
      )
    else
      govuk_tag(text:, classes: "nhsuk-tag--#{colour}")
    end
  end

  def triage_summary(triage)
    prefix =
      if (performed_by = triage.performed_by)
        "#{performed_by.full_name} decided that "
      else
        ""
      end

    suffix =
      if triage.safe_to_vaccinate?
        if triage.vaccine_method.present? &&
             triage.programme.has_multiple_vaccine_methods?
          vaccination_method =
            Vaccine.human_enum_name(:method_prefix, triage.vaccine_method)
          "is safe to vaccinate using the #{vaccination_method} vaccine only."
        else
          "is safe to vaccinate."
        end
      elsif triage.do_not_vaccinate?
        "should not be vaccinated."
      elsif triage.delay_vaccination?
        "’s vaccination should be delayed."
      end

    "#{prefix}#{triage.patient.full_name} #{suffix}" if suffix
  end
end
