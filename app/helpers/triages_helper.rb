# frozen_string_literal: true

module TriagesHelper
  def triage_status_text(triage)
    return if triage.nil?

    status_method =
      if triage.programme.has_multiple_vaccine_methods? &&
           triage.vaccine_method.present?
        triage.status + "_#{triage.vaccine_method}"
      else
        triage.status
      end

    Triage.human_enum_name(:status, status_method)
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
end
