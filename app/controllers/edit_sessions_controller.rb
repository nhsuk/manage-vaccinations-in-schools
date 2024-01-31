class EditSessionsController < ApplicationController
  include Wicked::Wizard
  include Wicked::Wizard::Translated # For custom URLs, see en.yml wicked

  layout "two_thirds"

  before_action :set_session
  before_action :set_steps
  before_action :setup_wizard_translated
  before_action :set_locations,
                only: %i[show update],
                if: -> { current_step == :location }
  before_action :set_campaigns,
                only: :show,
                if: -> { current_step == :vaccine }

  def show
    render_wizard
  end

  def update
    case current_step
    when :confirm
      @session.draft = false
    when :location, :vaccine
      @session.team = current_user.team
      @session.assign_attributes update_params
    else
      @session.assign_attributes update_params
    end

    render_wizard @session
  end

  private

  def current_step
    wizard_value(step)&.to_sym
  end

  def finish_wizard_path
    session_path(@session)
  end

  def set_session
    policy_scope_class =
      if params[:id] == "wicked_finish"
        SessionPolicy::Scope
      else
        SessionPolicy::DraftScope
      end

    @session =
      policy_scope(Session, policy_scope_class:).find(params[:session_id])
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
      ],
      location: [:location_id],
      vaccine: [:campaign_id]
    }.fetch(current_step)

    params
      .fetch(:session, {})
      .permit(permitted_attributes)
      .merge(form_step: current_step)
  end

  def set_steps
    self.steps = @session.form_steps
  end

  def set_locations
    @locations = policy_scope(Location).order(:name)
  end

  def set_campaigns
    @campaigns = policy_scope(Campaign).order(:created_at)
  end
end
