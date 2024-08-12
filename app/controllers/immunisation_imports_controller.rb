# frozen_string_literal: true

class ImmunisationImportsController < ApplicationController
  before_action :set_campaign

  layout "two_thirds", only: :new

  def index
    @immunisation_imports = @campaign.immunisation_imports.order(:created_at)
  end

  def new
    @immunisation_import = ImmunisationImport.new
  end

  def create
    @immunisation_import = ImmunisationImport.new(immunisation_import_params)

    @immunisation_import.load_data!
    if @immunisation_import.invalid?
      render :new, status: :unprocessable_entity
      return
    end

    @immunisation_import.parse_rows!
    if @immunisation_import.invalid?
      render :errors, status: :unprocessable_entity
      return
    end

    @immunisation_import.save!

    result = @immunisation_import.process!

    flash[:success] = "#{result[:count]} vaccinations uploaded"

    if (ignored_count = result[:ignored_count]) > 1
      flash[:info] = "#{ignored_count} un-administered vaccinations ignored"
    end

    redirect_to campaign_immunisation_import_path(
                  @campaign,
                  @immunisation_import
                )
  end

  def show
    @immunisation_import = @campaign.immunisation_imports.find(params[:id])

    @vaccination_records =
      @immunisation_import.vaccination_records.includes(
        :location,
        :patient,
        :session
      )
  end

  private

  def set_campaign
    @campaign =
      policy_scope(Campaign).includes(:immunisation_imports).find(
        params[:campaign_id]
      )
  end

  def immunisation_import_params
    params
      .fetch(:immunisation_import, {})
      .permit(:csv)
      .merge(user: current_user, campaign: @campaign)
  end
end
