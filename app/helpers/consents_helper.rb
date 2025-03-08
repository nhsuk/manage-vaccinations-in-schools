# frozen_string_literal: true

module ConsentsHelper
  def consent_decision(consent)
    if consent.invalidated?
      safe_join([tag.s(consent.human_enum_name(:response)), "Invalid"], tag.br)
    elsif consent.withdrawn?
      safe_join([tag.s("Consent given"), "Withdrawn"], tag.br)
    else
      consent.human_enum_name(:response)
    end
  end
end
