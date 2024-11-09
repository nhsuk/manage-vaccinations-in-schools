# frozen_string_literal: true

module WizardControllerConcern
  extend ActiveSupport::Concern

  include Wicked::Wizard::Translated

  included do
    before_action :set_steps
    before_action :setup_wizard_translated
  end

  def current_step
    @current_step ||= wizard_value(step)&.to_sym
  end
end
