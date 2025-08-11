# frozen_string_literal: true

class SchoolMoves::ExportsController < ApplicationController
  before_action :set_school_move_export

  include WizardControllerConcern

  skip_after_action :verify_policy_scoped

  def create
    @school_move_export.clear!
    redirect_to school_move_export_path(Wicked::FIRST_STEP)
  end

  def show
    render_wizard
  end

  def update
    @school_move_export.assign_attributes(update_params)

    render_wizard @school_move_export
  end

  def download
    send_data(
      @school_move_export.csv_data,
      filename: @school_move_export.csv_filename
    )
  end

  def finish_wizard_path
    download_school_move_export_path
  end

  def set_school_move_export
    @school_move_export =
      SchoolMoveExport.new(request_session: session, current_user:)
  end

  def set_steps
    self.steps = @school_move_export.wizard_steps
  end

  def update_params
    params
      .fetch(:school_move_export, {})
      .permit(:date_from, :date_to)
      .merge(wizard_step: current_step)
  end
end
