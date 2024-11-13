# frozen_string_literal: true

class VaccinationReportsController < ApplicationController
  before_action :set_vaccination_report
  before_action :set_programme, only: %i[show update]

  include WizardControllerConcern

  skip_after_action :verify_policy_scoped, only: %i[show update download]

  def create
    @programme = policy_scope(Programme).find_by(type: params[:programme_type])

    @vaccination_report.reset!
    @vaccination_report.update!(programme: @programme)

    redirect_to vaccination_report_path(Wicked::FIRST_STEP)
  end

  def download
    # TODO: download the real data
    send_data("", filename: @vaccination_report.filename)
  end

  def show
    render_wizard
  end

  def update
    @vaccination_report.assign_attributes(update_params)

    render_wizard @vaccination_report
  end

  private

  def set_vaccination_report
    @vaccination_report =
      VaccinationReport.new(request_session: session, current_user:)
  end

  def set_programme
    @programme = @vaccination_report.programme
  end

  def set_steps
    self.steps = @vaccination_report.wizard_steps
  end

  def finish_wizard_path
    download_vaccination_report_path
  end

  def update_params
    params
      .require(:vaccination_report)
      .permit(:date_from, :date_to, :file_format)
      .merge(wizard_step: current_step)
  end
end
