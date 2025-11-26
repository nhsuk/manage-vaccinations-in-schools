# frozen_string_literal: true

class VaccinationReportsController < ApplicationController
  before_action :set_vaccination_report, except: %i[new create]
  before_action :set_programme, except: %i[new create]
  before_action :set_academic_year, except: %i[new create]

  include WizardControllerConcern

  skip_after_action :verify_policy_scoped

  def new
    @vaccination_report =
      VaccinationReport.new(
        current_user:,
        request_session: {
        },
        academic_year: AcademicYear.current
      )
  end

  def create
    @vaccination_report =
      VaccinationReport.new(current_user:, request_session: {}, **create_params)

    if @vaccination_report.valid?(:single_page)
      send_data(
        @vaccination_report.csv_data,
        filename: @vaccination_report.csv_filename
      )
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    render_wizard
  end

  def update
    @vaccination_report.assign_attributes(update_params)

    render_wizard @vaccination_report
  end

  def download
    if @vaccination_report.valid?
      send_data(
        @vaccination_report.csv_data,
        filename: @vaccination_report.csv_filename
      )
    else
      redirect_to vaccination_report_path(Wicked::FIRST_STEP)
    end
  end

  private

  def set_vaccination_report
    @vaccination_report =
      VaccinationReport.new(request_session: session, current_user:)
  end

  def set_programme
    @programme = @vaccination_report.programme
    redirect_to dashboard_path if @programme.nil?
  end

  def set_academic_year
    @academic_year = @vaccination_report.academic_year
    redirect_to dashboard_path if @programme.nil?
  end

  def set_steps
    self.steps = @vaccination_report.wizard_steps
  end

  def finish_wizard_path
    download_vaccination_report_path
  end

  def update_params
    params.expect(vaccination_report: %i[date_from date_to file_format]).merge(
      wizard_step: current_step
    )
  end

  def create_params
    params.expect(
      vaccination_report: %i[
        academic_year
        programme_type
        date_from
        date_to
        file_format
      ]
    )
  end
end
