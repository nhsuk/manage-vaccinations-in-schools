# frozen_string_literal: true

module TriagesHelper
  def triage_status_tag(triage)
    status_method =
      if triage.programme.has_multiple_vaccine_methods? &&
           triage.vaccine_method.present?
        triage.status + "_#{triage.vaccine_method}"
      else
        triage.status
      end

    text = Triage.human_enum_name(:status, status_method)

    colour =
      if triage.invalidated?
        "grey"
      elsif triage.ready_to_vaccinate?
        "green"
      elsif triage.do_not_vaccinate?
        "red"
      else
        "blue"
      end

    if triage.invalidated?
      safe_join(
        [
          govuk_tag(text: tag.s(text), colour:),
          tag.span("Invalid", class: "nhsuk-u-secondary-text-color")
        ]
      )
    else
      govuk_tag(text:, colour:)
    end
  end
end
