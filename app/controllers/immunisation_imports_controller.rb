# frozen_string_literal: true

class ImmunisationImportsController < ApplicationController
  before_action :set_campaign
  before_action :set_immunisation_import, only: %i[show edit update]
  before_action :set_vaccination_records, only: %i[edit show]
  before_action :set_patients_with_changes, only: %i[edit]

  def index
    @immunisation_imports =
      @campaign
        .immunisation_imports
        .recorded
        .includes(:user)
        .order(:created_at)
        .strict_loading

    render layout: "full"
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

    @immunisation_import.process!

    if @immunisation_import.new_record_count.zero? &&
         @immunisation_import.exact_duplicate_record_count != 0
      render :duplicates
      return
    end

    redirect_to edit_campaign_immunisation_import_path(
                  @campaign,
                  @immunisation_import
                )
  end

  def show
  end

  def edit
    render layout: "full"
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

  def set_patients_with_changes
    @patients =
      @vaccination_records
        .map(&:patient)
        .select { _1.pending_changes.present? }
        .uniq
  end

  def immunisation_import_params
    params
      .fetch(:immunisation_import, {})
      .permit(:csv)
      .merge(user: current_user, campaign: @campaign)
  end
end
