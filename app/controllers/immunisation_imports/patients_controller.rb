# frozen_string_literal: true

class ImmunisationImports::PatientsController < ApplicationController
  before_action :set_programme
  before_action :set_immunisation_import
  before_action :set_patient

  def show
    render layout: "full"
  end

  def update
  end

  private

  def set_programme
    @programme =
      policy_scope(Programme)
        .active
        .includes(:immunisation_imports)
        .find(params[:programme_id])
  end

  def set_immunisation_import
    @immunisation_import =
      @programme.immunisation_imports.find(params[:immunisation_import_id])
  end

  def set_patient
    @patient =
      Patient
        .joins(patient_sessions: :vaccination_records)
        .where(
          patient_sessions: {
            vaccination_records: {
              imported_from: @immunisation_import
            }
          }
        )
        .find(params[:id])
  end
end
