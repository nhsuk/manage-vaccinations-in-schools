# frozen_string_literal: true

module TriagesHelper
  def triage_status_tag(triage)
    text = triage.human_enum_name(:status)

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
