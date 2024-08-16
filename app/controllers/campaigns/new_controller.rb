# frozen_string_literal: true

class Campaigns::NewController < ApplicationController
  include Wicked::Wizard

  before_action :set_campaign
  before_action :set_steps
  before_action :setup_wizard

  skip_after_action :verify_policy_scoped

  layout "two_thirds"

  def show
    render_wizard
  end

  def update
    params = send("#{current_step}_params")

    @campaign.assign_attributes(form_step: current_step, **params)

    render_wizard(@campaign)
  end

  private

  def set_campaign
    @campaign =
      policy_scope(Campaign).where(
        active: params[:id] == Wicked::FINISH_STEP
      ).find(params[:campaign_id])
  end

  def set_steps
    self.steps = @campaign.form_steps
  end

  def finish_wizard_path
    campaign_path(@campaign)
  end

  def current_step
    @current_step ||= wizard_value(step).to_sym
  end

  def details_params
    params.require(:campaign).permit(:name, :academic_year, :type)
  end

  def dates_params
    params.require(:campaign).permit(:start_date, :end_date)
  end

  def confirm_params
    { active: true, vaccines: Vaccine.active.where(type: @campaign.type) }
  end
end
