# frozen_string_literal: true

class ClassImportsController < ApplicationController
  before_action :set_session
  before_action :set_class_import, only: %i[show edit update]
  before_action :set_patients, only: %i[show edit]

  def new
    @class_import = ClassImport.new
  end

  def create
    @class_import =
      ClassImport.new(
        session: @session,
        team: current_user.team,
        uploaded_by: current_user,
        **class_import_params
      )

    @class_import.load_data!
    if @class_import.invalid?
      render :new, status: :unprocessable_entity and return
    end

    @class_import.save!

    ProcessImportJob.perform_later(@class_import)

    redirect_to programme_imports_path(@session.programmes.first),
                flash: {
                  success: "Import processing started"
                }
  end

  def show
    render layout: "full"
  end

  def edit
    if @class_import.rows_are_invalid?
      @class_import.load_serialized_errors!
      render :errors and return
    end

    render layout: "full"
  end

  def update
    @class_import.record!

    redirect_to session_class_import_path(@session, @class_import)
  end

  private

  def set_session
    @session = policy_scope(Session).find(params[:session_id])
  end

  def set_class_import
    @class_import = policy_scope(ClassImport).find(params[:id])
  end

  def set_patients
    @patients = @class_import.patients
  end

  def class_import_params
    params.fetch(:class_import, {}).permit(:csv)
  end
end
