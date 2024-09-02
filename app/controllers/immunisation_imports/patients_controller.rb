# frozen_string_literal: true

class ImmunisationImports::PatientsController < ApplicationController
  before_action :set_campaign
  before_action :set_immunisation_import
  before_action :set_patient

  def show
    render layout: "full"
  end

  def update
  end

  private

  def set_campaign
    @campaign =
      policy_scope(Campaign)
        .active
        .includes(:immunisation_imports)
        .find(params[:campaign_id])
  end

  def set_immunisation_import
    @immunisation_import =
      @campaign.immunisation_imports.find(params[:immunisation_import_id])
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
