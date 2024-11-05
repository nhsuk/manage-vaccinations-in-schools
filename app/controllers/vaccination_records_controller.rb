# frozen_string_literal: true

class VaccinationRecordsController < ApplicationController
  include Pagy::Backend

  before_action :set_vaccination_record, except: :index

  def index
    @pagy, @vaccination_records = pagy(vaccination_records.recorded)

    render layout: "full"
  end

  def show
  end

  def edit
  end

  def export_dps
    send_data(dps_export.csv, filename: dps_export.filename)
  end

  def reset_dps_export
    programme.dps_exports.destroy_all

    flash[:success] = {
      heading: "DPS exports have been reset for the programme"
    }

    redirect_to programme_vaccination_records_path(programme)
  end

  private

  def programme
    @programme ||=
      policy_scope(Programme).find_by!(type: params[:programme_type])
  end

  def vaccination_records
    @vaccination_records ||=
      policy_scope(VaccinationRecord)
        .includes(
          :batch,
          :immunisation_imports,
          :location,
          :performed_by_user,
          :programme,
          patient: [:cohort, :school, { parents: :parent_relationships }],
          session: %i[session_dates],
          vaccine: :programme
        )
        .where(programme:)
        .order(:recorded_at)
        .strict_loading
  end

  def dps_export
    @dps_export ||= DPSExport.create!(programme:)
  end

  def set_vaccination_record
    @vaccination_record = vaccination_records.find(params[:id])
    @patient = @vaccination_record.patient
    @session = @vaccination_record.session
  end
end
