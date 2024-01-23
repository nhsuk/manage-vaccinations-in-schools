class EditSessionsController < ApplicationController
  include Wicked::Wizard

  layout "two_thirds"

  before_action :set_session

  steps :confirm

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
end
