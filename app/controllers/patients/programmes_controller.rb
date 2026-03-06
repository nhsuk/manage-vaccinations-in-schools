# frozen_string_literal: true

class Patients::ProgrammesController < Patients::BaseController
  before_action :set_programme
  before_action :set_in_generic_clinic

  skip_after_action :verify_policy_scoped

  layout "full"

  def show
    authorize @patient
  end

  private

  def set_programme
    return unless params.key?(:id)

    @programme = Programme.find(params[:id], patient: @patient)

    raise ActiveRecord::RecordNotFound if @programme.nil?
  end

  def set_in_generic_clinic
    @in_generic_clinic =
      @patient.patient_locations.exists?(
        location: current_team.generic_clinic,
        academic_year: AcademicYear.pending
      )
  end
end
