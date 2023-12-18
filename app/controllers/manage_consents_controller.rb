class ManageConsentsController < ApplicationController
  include Wicked::Wizard
  include Wicked::Wizard::Translated # For custom URLs, see en.yml wicked

  layout "two_thirds"

  before_action :set_consent
  before_action :set_steps
  before_action :setup_wizard_translated

  def show
    render_wizard
  end

  def update
    render_wizard @consent
  end

  private

  def current_step
    wizard_value(step).to_sym
  end

  def set_consent
    @consent = Consent.find_or_initialize_by(id: params[:consent_id])
  end

  def set_steps
    self.steps = @consent.form_steps
  end
end
