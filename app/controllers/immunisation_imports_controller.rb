# frozen_string_literal: true

class ImmunisationImportsController < ApplicationController
  before_action :set_campaign
  before_action :set_immunisation_import, only: %i[show edit update]
  before_action :set_vaccination_records, only: %i[edit show]

  layout "two_thirds", only: :new

  def index
    @immunisation_imports =
      @campaign
        .immunisation_imports
        .recorded
        .includes(:user)
        .order(:created_at)
        .strict_loading
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

    result = @immunisation_import.process!

    if result[:new_count].zero? && result[:duplicate_count] != 0
      render :duplicates
      return
    end

    flash[:success] = "#{result[:new_count]} vaccinations uploaded"

    # TODO: Move to "Check and confirm" page
    if (duplicate_count = result[:duplicate_count]) > 1
      flash[
        :info
      ] = "#{duplicate_count} previously uploaded records were omitted"
    end

    if (ignored_count = result[:ignored_count]) > 1
      flash[
        :info
      ] = "#{ignored_count} records for children who were not vaccinated were omitted"
    end

    redirect_to edit_campaign_immunisation_import_path(
                  @campaign,
                  @immunisation_import
                )
  end

  def show
  end

  def edit
  end

  def update
    @immunisation_import.record!

    redirect_to campaign_immunisation_import_path(
                  @campaign,
                  @immunisation_import
                )
  end

  private

  def set_campaign
    @campaign =
      policy_scope(Campaign)
        .active
        .includes(:immunisation_imports)
        .find(params[:campaign_id])
  end

  def set_immunisation_import
    @immunisation_import = @campaign.immunisation_imports.find(params[:id])
  end

  def set_vaccination_records
    @vaccination_records =
      @immunisation_import.vaccination_records.includes(
        :location,
        :patient,
        :session
      )
  end

  def immunisation_import_params
    params
      .fetch(:immunisation_import, {})
      .permit(:csv)
      .merge(user: current_user, campaign: @campaign)
  end
end
