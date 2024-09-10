# frozen_string_literal: true

class ImmunisationImportsController < ApplicationController
  before_action :set_programme
  before_action :set_immunisation_import, only: %i[show edit update]
  before_action :set_vaccination_records, only: %i[show edit]
  before_action :set_patients_with_changes, only: %i[edit]

  def index
    @immunisation_imports =
      @programme
        .immunisation_imports
        .recorded
        .includes(:uploaded_by)
        .order(:created_at)
        .strict_loading

    render layout: "full"
  end

  def new
    @immunisation_import = ImmunisationImport.new
  end

  def create
    @immunisation_import =
      ImmunisationImport.new(
        uploaded_by: current_user,
        programme: @programme,
        **immunisation_import_params
      )

    @immunisation_import.load_data!
    if @immunisation_import.invalid?
      render :new, status: :unprocessable_entity and return
    end

    @immunisation_import.parse_rows!
    if @immunisation_import.invalid?
      render :errors, status: :unprocessable_entity and return
    end

    @immunisation_import.process!

    if @immunisation_import.processed_only_exact_duplicates?
      render :duplicates and return
    end

    redirect_to edit_programme_immunisation_import_path(
                  @programme,
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

    redirect_to programme_immunisation_import_path(
                  @programme,
                  @immunisation_import
                )
  end

  private

  def set_programme
    @programme =
      policy_scope(Programme)
        .active
        .includes(:immunisation_imports)
        .find(params[:programme_id])
  end

  def set_immunisation_import
    @immunisation_import = @programme.immunisation_imports.find(params[:id])
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
    params.fetch(:immunisation_import, {}).permit(:csv)
  end
end
