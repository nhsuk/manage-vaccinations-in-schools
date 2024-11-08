# frozen_string_literal: true

module GillickAssessmentsHelper
  # rubocop:disable Rails/HelperInstanceVariable
  def draft_gillick_assessment_back_link_path
    if @draft_gillick_assessment.editing?
      wizard_path("confirm")
    elsif current_step?(@draft_gillick_assessment.wizard_steps.first.to_s)
      session_patient_path(
        @session,
        @patient,
        section: "consents",
        tab: "no-consent"
      )
    else
      previous_wizard_path
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable
end
