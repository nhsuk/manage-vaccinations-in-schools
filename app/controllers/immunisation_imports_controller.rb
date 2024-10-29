# frozen_string_literal: true

class ImmunisationImportsController < ApplicationController
  include Pagy::Backend

  before_action :set_programme
  before_action :set_immunisation_import, only: %i[show update]

  def new
    @immunisation_import = ImmunisationImport.new
  end

  def create
    @immunisation_import =
      ImmunisationImport.new(
        programme: @programme,
        team: current_user.selected_team,
        uploaded_by: current_user,
        **immunisation_import_params
      )

    @immunisation_import.load_data!
    if @immunisation_import.invalid?
      render :new, status: :unprocessable_entity and return
    end

    @immunisation_import.save!

    if @immunisation_import.slow?
      ProcessImportJob.perform_later(@immunisation_import)
      flash = { success: "Import processing started" }
    else
      ProcessImportJob.perform_now(@immunisation_import)
      flash = { success: "Import completed" }
    end

    redirect_to programme_imports_path(@programme), flash:
  end

  def show
    if @immunisation_import.rows_are_invalid?
      @immunisation_import.load_serialized_errors!
    end

    vaccination_records =
      @immunisation_import.vaccination_records.recorded.includes(
        :location,
        :patient,
        :session
      )

    @pagy, @vaccination_records = pagy(vaccination_records)

    @duplicates = vaccination_records.with_pending_changes.distinct

    render template: "imports/show",
           layout: "full",
           locals: {
             import: @immunisation_import
           }
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
    @programme = policy_scope(Programme).find_by!(type: params[:programme_type])
  end

  def set_immunisation_import
    @immunisation_import =
      policy_scope(ImmunisationImport).where(programme: @programme).find(
        params[:id]
      )
  end

  def immunisation_import_params
    params.fetch(:immunisation_import, {}).permit(:csv)
  end
end
