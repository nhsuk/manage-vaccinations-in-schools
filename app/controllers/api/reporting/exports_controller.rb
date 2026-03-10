# frozen_string_literal: true

class API::Reporting::ExportsController < API::Reporting::BaseController
  before_action :set_team, only: %i[form_options create index]
  before_action :set_export, only: %i[show download]

  def index
    authorize VaccinationReportExport.new(team: @team), :index?

    exports =
      VaccinationReportExport
        .where(team: @team, user: current_user)
        .order(created_at: :desc)

    render json: exports.map { |export| export_as_json(export) }
  end

  def form_options
    export = VaccinationReportExport.new(team: @team)
    authorize export, :form_options?

    render json: { file_formats: export.file_formats }
  end

  def create
    @export = VaccinationReportExport.new(export_params.except(:workgroup))
    @export.team = @team
    @export.user = current_user

    authorize @export

    if @export.save
      if Rails.env.end_to_end?
        GenerateVaccinationReportJob.perform_now(@export.id)
        @export.reload
      else
        GenerateVaccinationReportJob.perform_later(@export.id)
      end
      render json: { id: @export.id, status: @export.status }, status: :created
    else
      render json: { errors: @export.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    authorize @export

    @export.expired! if @export.expired? && @export.status != "expired"

    data = {
      status: @export.status,
      expires_at: @export.expired_at&.iso8601
    }
    if @export.ready? && !@export.expired?
      data[:download_url] = download_api_reporting_export_url(@export)
    end

    render json: data
  end

  def download
    authorize @export, :download?

    if @export.file.attached?
      send_data @export.file.download,
                type: @export.file.content_type || "text/csv",
                filename: @export.file.filename.to_s,
                disposition: :attachment
    else
      head :not_found
    end
  end

  private

  def set_team
    workgroup = params[:workgroup].presence || cis2_info.team_workgroup
    raise ActiveRecord::RecordNotFound if workgroup.blank?

    @team = current_user.teams.find_by!(workgroup:)
  rescue ActiveRecord::RecordNotFound
    render json: { errors: "Team not found" }, status: :not_found
  end

  def set_export
    @export = VaccinationReportExport.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { errors: "Export not found" }, status: :not_found
  end

  def export_params
    params.permit(:programme_type, :academic_year, :date_from, :date_to, :file_format, :workgroup)
  end

  def export_as_json(export)
    expired = export.expired?
    status = expired ? "expired" : export.status
    item = {
      id: export.id,
      status:,
      programme_type: export.programme_type,
      file_format: export.file_format,
      academic_year: export.academic_year,
      date_from: export.date_from&.iso8601,
      date_to: export.date_to&.iso8601,
      created_at: export.created_at.iso8601,
      expired_at: export.expired_at&.iso8601
    }
    item[:download_url] = download_api_reporting_export_url(export) if export.ready? && !expired
    item
  end
end
