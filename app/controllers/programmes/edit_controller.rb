# frozen_string_literal: true

class Programmes::EditController < ApplicationController
  include Wicked::Wizard

  before_action :set_programme
  before_action :set_steps
  before_action :setup_wizard

  def show
    render_wizard
  end

  def update
    params = send("#{step}_params")

    @programme.assign_attributes(wizard_step: step, **params)

    if current_step?(:details) && @programme.type_changed?
      @programme.vaccines = Vaccine.active.where(type: @programme.type)
    end

    jump_to(:confirm) if @programme.active && !current_step?(:confirm)

    render_wizard(@programme)
  end

  private

  def set_programme
    @programme =
      policy_scope(Programme).includes(:vaccines).find(params[:programme_id])
  end

  def set_steps
    self.steps = @programme.wizard_steps
  end

  def finish_wizard_path
    programme_path(@programme)
  end

  def details_params
    params.require(:programme).permit(:name, :academic_year, :type)
  end

  def dates_params
    params.require(:programme).permit(:start_date, :end_date)
  end

  def vaccines_params
    params.require(:programme).permit(vaccine_ids: [])
  end

  def confirm_params
    { active: true }
  end
end
