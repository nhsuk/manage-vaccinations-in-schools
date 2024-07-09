# frozen_string_literal: true

class ImmunisationImportsController < ApplicationController
  before_action :set_campaign

  def new
    @immunisation_import = ImmunisationImport.new
  end

  def create
    @immunisation_import = ImmunisationImport.new(immunisation_import_params)

    if @immunisation_import.save
      redirect_to success_campaign_immunisation_import_path(
                    @campaign,
                    @immunisation_import
                  )
    else
      render :new, status: :unprocessable_entity
    end
  end

  def success
  end

  private

  def set_campaign
    @campaign = policy_scope(Campaign).find(params[:campaign_id])
  end

  def immunisation_import_params
    params
      .fetch(:immunisation_import, {})
      .permit(:csv)
      .merge(user: current_user)
  end
end
