# frozen_string_literal: true

module ConsentsHelper
  def consent_decision(consent)
    if consent.invalidated?
      safe_join(
        [
          tag.s(Consent.human_enum_name(:response, consent.response).humanize),
          "Invalid"
        ],
        tag.br
      )
    elsif consent.withdrawn?
      safe_join([tag.s("Consent given"), "Withdrawn"], tag.br)
    else
      Consent.human_enum_name(:response, consent.response).humanize
    end
  end
end
