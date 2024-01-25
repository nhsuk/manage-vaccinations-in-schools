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

  def set_steps
    self.steps = @session.form_steps
  end
end
