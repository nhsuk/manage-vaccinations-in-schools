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

  # rubocop:disable Rails/HelperInstanceVariable
  def consents_back_link_path
    if @draft_consent.editing?
      wizard_path("confirm")
    elsif current_step?(@draft_consent.wizard_steps.first.to_s)
      session_patient_path(
        @session,
        id: @patient.id,
        section: "consents",
        tab: "no-consent"
      )
    else
      previous_wizard_path
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable
end
