# frozen_string_literal: true

class ImmunisationImports::DuplicatesController < ApplicationController
  before_action :set_programme
  before_action :set_immunisation_import
  before_action :set_patient
  before_action :set_form

  def show
    render layout: "full"
  end

  def update
    if @form.save
      redirect_to edit_programme_immunisation_import_path(
                    @programme,
                    @immunisation_import
                  ),
                  flash: {
                    success: "Vaccination record updated"
                  }
    else
      render :show, status: :unprocessable_entity, layout: "full" and return
    end
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
    @patient = @immunisation_import.patients.find(params[:id])
  end

  def set_form
    apply_changes = params.dig(:patient_changes_form, :apply_changes)

    @form = PatientChangesForm.new(patient: @patient, apply_changes:)
  end
end
