# frozen_string_literal: true

module ConsentsHelper
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
