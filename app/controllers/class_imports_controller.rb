# frozen_string_literal: true

class ClassImportsController < ApplicationController
  include Pagy::Backend

  before_action :set_draft_import, only: %i[new create]
  before_action :set_class_import, only: %i[show update]

  skip_after_action :verify_policy_scoped, only: %i[new create]

  def new
    @class_import = ClassImport.new(team: current_team)
  end

  def create
    @class_import =
      ClassImport.new(
        academic_year: AcademicYear.pending,
        location: @location,
        team: current_team,
        uploaded_by: current_user,
        year_groups: @draft_import.year_groups,
        **class_import_params
      )

    @class_import.load_data!
    if @class_import.invalid?
      render :new, status: :unprocessable_entity and return
    end

    @class_import.save!

    if @class_import.slow?
      ProcessImportJob.perform_later(@class_import)
      redirect_to imports_path, flash: { success: "Import processing started" }
    else
      ProcessImportJob.perform_now(@class_import)
      redirect_to class_import_path(@class_import)
    end
  end

  def show
    @class_import.load_serialized_errors! if @class_import.rows_are_invalid?

    @pagy, @patients = pagy(@class_import.patients.includes(:school))

    @duplicates = @class_import.patients.with_pending_changes.distinct

    render template: "imports/show",
           layout: "full",
           locals: {
             import: @class_import
           }
  end

  def update
    @class_import.process!

    redirect_to class_import_path(@class_import)
  end

  private

  def set_draft_import
    @draft_import = DraftImport.new(request_session: session, current_user:)
    @location = @draft_import.location
  end

  def set_class_import
    @class_import =
      policy_scope(ClassImport).includes(:location).find(params[:id])
    @location = @class_import.location
  end

  def class_import_params
    params.fetch(:class_import, {}).permit(:csv)
  end
end
