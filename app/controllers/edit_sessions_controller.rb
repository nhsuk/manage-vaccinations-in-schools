class EditSessionsController < ApplicationController
  include Wicked::Wizard
  include Wicked::Wizard::Translated # For custom URLs, see en.yml wicked

  layout "two_thirds"

  before_action :set_session
  before_action :set_steps
  before_action :setup_wizard_translated

  def show
    render_wizard
  end

  def update
    case current_step
    when :timeline
      @session.assign_attributes update_params
    when :confirm
      @session.draft = false
    end

    render_wizard @session
  end

  private

  def current_step
    wizard_value(step).to_sym
  end

  def finish_wizard_path
    session_path(@session)
  end

  def set_session
    @session = current_user.team.campaign.sessions.find(params[:session_id])
  end

  def update_params
    permitted_attributes = {
      timeline: %i[
        consent_days_before
        consent_days_before_custom
        reminder_days_after
        reminder_days_after_custom
        close_consent_on
        close_consent_at
      ]
    }.fetch(current_step)

    params
      .fetch(:session, {})
      .permit(permitted_attributes)
      .merge(form_step: current_step)
  end

  def set_steps
    self.steps = @session.form_steps
  end
end
