# frozen_string_literal: true

class ImmunisationImportsController < ApplicationController
  include Pagy::Backend

  before_action :set_immunisation_import, only: %i[show update]

  skip_after_action :verify_policy_scoped, only: %i[new create]

  def new
    @immunisation_import = ImmunisationImport.new(team: current_team)
  end

  def create
    @immunisation_import =
      ImmunisationImport.new(
        team: current_team,
        uploaded_by: current_user,
        **immunisation_import_params
      )

    @immunisation_import.load_data!
    if @immunisation_import.invalid?
      render :new, status: :unprocessable_content and return
    end

    @immunisation_import.save!

    ProcessImportJob.perform_later(@immunisation_import)
    redirect_to imports_path, flash: { success: "Import processing started" }
  end

  def show
    if @immunisation_import.rows_are_invalid?
      @immunisation_import.load_serialized_errors!
    end

    vaccination_records =
      @immunisation_import.vaccination_records.includes(
        :location,
        :session,
        patient: :school
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
    @immunisation_import.process!

    redirect_to immunisation_import_path(@immunisation_import)
  end

  private

  def set_immunisation_import
    @immunisation_import = policy_scope(ImmunisationImport).find(params[:id])
  end

  def immunisation_import_params
    params.fetch(:immunisation_import, {}).permit(:csv)
  end
end
