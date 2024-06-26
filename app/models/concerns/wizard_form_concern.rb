# frozen_string_literal: true

module WizardFormConcern
  extend ActiveSupport::Concern

  included { attr_accessor :form_step }

  class_methods do
    def on_wizard_step(step, exact: false, &block)
      with_options on: :update do
        with_options if: -> { required_for_step?(step, exact:) }, &block
      end
    end
  end

  private

  def required_for_step?(step, exact: false)
    # Exact means that the form_step must match the step
    return false if exact && form_step != step

    # Step can't be required if it's not in the current form_steps list
    return false unless step.in?(form_steps)

    # All fields are required if no form_step is set
    return true if form_step.nil?

    # Otherwise, all fields from previous and current steps are required
    return true if form_steps.index(step) <= form_steps.index(form_step)

    false
  end
end
