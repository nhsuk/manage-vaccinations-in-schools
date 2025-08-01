# frozen_string_literal: true

module WizardControllerConcern
  extend ActiveSupport::Concern

  include Wicked::Wizard::Translated

  included do
    with_options only: %i[show update] do
      before_action :set_steps
      before_action :setup_wizard_translated
    end
  end

  def current_step
    @current_step ||= wizard_value(step)&.to_sym
  end

  def reload_steps
    # Translated steps are cached after running setup_wizard_translated.
    # To allow us to run this method multiple times during a single action
    # lifecycle, we need to clear the cache.
    @wizard_translations = nil

    set_steps

    setup_wizard_translated
  end
end
