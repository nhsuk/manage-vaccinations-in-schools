# frozen_string_literal: true

module ConsentsHelper
  def consent_decision(consent)
    if consent.withdrawn?
      safe_join([tag.s("Consent given"), "Withdrawn"], tag.br)
    else
      consent.human_enum_name(:response).humanize
    end
  end

  # rubocop:disable Rails/HelperInstanceVariable
  def consents_back_link_path
    if @consent.wizard_steps.first == @current_step
      session_patient_path(@session, id: @patient.id)
    else
      previous_wizard_path
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable
end
