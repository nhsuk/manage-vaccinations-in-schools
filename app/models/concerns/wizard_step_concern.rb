# frozen_string_literal: true

module WizardStepConcern
  extend ActiveSupport::Concern

  included { attr_accessor :wizard_step }

  class_methods do
    def on_wizard_step(step, exact: false, &block)
      with_options on: :update do
        with_options if: -> { required_for_step?(step, exact:) }, &block
      end
    end
  end

  private

  def required_for_step?(step, exact: false)
    # Exact means that the wizard_step must match the step
    return false if exact && wizard_step != step

    # Step can't be required if it's not in the current wizard_steps list
    return false unless step.in?(wizard_steps)

    # All fields are required if no wizard_step is set
    return true if wizard_step.nil?

    # Otherwise, all fields from previous and current steps are required
    return true if wizard_steps.index(step) <= wizard_steps.index(wizard_step)

    false
  end
end
