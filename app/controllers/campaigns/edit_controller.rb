# frozen_string_literal: true

class Campaigns::EditController < ApplicationController
  include Wicked::Wizard

  before_action :set_campaign
  before_action :set_steps
  before_action :setup_wizard

  def show
    render_wizard
  end

  def update
    params = send("#{step}_params")

    @campaign.assign_attributes(wizard_step: step, **params)

    if current_step?(:details) && @campaign.type_changed?
      @campaign.vaccines = Vaccine.active.where(type: @campaign.type)
    end

    jump_to(:confirm) if @campaign.active && !current_step?(:confirm)

    render_wizard(@campaign)
  end

  private

  def set_campaign
    @campaign =
      policy_scope(Campaign).includes(:vaccines).find(params[:campaign_id])
  end

  def set_steps
    self.steps = @campaign.wizard_steps
  end

  def finish_wizard_path
    campaign_path(@campaign)
  end

  def details_params
    params.require(:campaign).permit(:name, :academic_year, :type)
  end

  def dates_params
    params.require(:campaign).permit(:start_date, :end_date)
  end

  def confirm_params
    { active: true }
  end
end
