# frozen_string_literal: true

class ImmunisationImportsController < ApplicationController
  before_action :set_programme
  before_action :set_immunisation_import, only: %i[show edit update]
  before_action :set_vaccination_records, only: %i[show edit]
  before_action :set_vaccination_records_with_pending_changes, only: %i[edit]

  def new
    @immunisation_import = ImmunisationImport.new
  end

  def create
    @immunisation_import =
      ImmunisationImport.new(
        programme: @programme,
        team: current_user.team,
        uploaded_by: current_user,
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

    redirect_to edit_programme_immunisation_import_path(
                  @programme,
                  @immunisation_import
                )
  end

  def show
    render layout: "full"
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
    @programme = policy_scope(Programme).find(params[:programme_id])
  end

  def set_immunisation_import
    @immunisation_import =
      policy_scope(ImmunisationImport).where(programme: @programme).find(
        params[:id]
      )
  end

  def set_vaccination_records
    @vaccination_records =
      @immunisation_import.vaccination_records.includes(
        :location,
        :patient,
        :session
      )
  end

  def set_vaccination_records_with_pending_changes
    @vaccination_records_with_pending_changes =
      @vaccination_records
        .left_joins(:patient)
        .where(
          "patients.pending_changes != '{}' OR vaccination_records.pending_changes != '{}'"
        )
        .distinct
  end

  def immunisation_import_params
    params.fetch(:immunisation_import, {}).permit(:csv)
  end
end
